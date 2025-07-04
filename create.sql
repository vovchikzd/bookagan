create or replace function auto_update_dates_trigger_fn()
returns trigger as $$
begin
  if new.dCreateDate is distinct from old.dCreateDate then
    raise exception 'Editing of column "dCreateDate" is prohibited';
  end if;

  new.dUpdateDate = current_timestamp;
  return new;
end;
$$ language plpgsql;


create table if not exists Bkg_Language (
  id bigserial primary key
  , sISO1 varchar(2) not null
  , sISO2 varchar(3) not null
  , sISO3 varchar(3) not null
  , sEnglishName varchar(20)
  , sNativeName varchar(20)
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , constraint bkg_codes_unique_tuple unique (sISO1, sISO2, sISO3)
);

create or replace trigger bkg_language_update_row_modified_date
before update on Bkg_Language
for each row
execute function auto_update_dates_trigger_fn();

insert into Bkg_Language (sISO1, sISO2, sISO3, sEnglishName, sNativeName)
values
  ('en', 'eng', 'eng', 'English', 'English')
  , ('ru', 'rus', 'rus', 'Russian', 'Русский')
  , ('fr', 'fre', 'fra', 'French', 'Français')
  , ('de', 'ger', 'deu', 'German', 'Deutsch')
  , ('pl', 'pol', 'pol', 'Polish', 'Polski')
  , ('he', 'heb', 'heb', 'Hebrew', 'עברית');


create table if not exists Bkg_Authors (
  id bigserial primary key
  , idLanguage int8 not null
  , sFirstName varchar(100)
  , sLastName varchar(100)
  , sMiddleName varchar(100)
  , sCoverName varchar(100)
  , bIsOriginLang boolean not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idLanguage) references Bkg_Language(id)
);

create or replace trigger bkg_authors_update_row_modified_date
before update on Bkg_Authors
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_AuthorsTranslate (
  id bigserial primary key
  , idAuthor int8 not null
  , idLanguage int8 not null
  , sFirstName varchar(100)
  , sLastName varchar(100)
  , sMiddleName varchar(100)
  , sCoverName varchar(100)
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idAuthor) references Bkg_Authors(id) on delete cascade
  , foreign key (idLanguage) references Bkg_Language(id)
);

create or replace trigger bkg_authorstranslate_update_row_modified_date
before update on Bkg_AuthorsTranslate
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_Works (
  id bigserial primary key
  , idLanguage int8 not null
  , idOriginLanguage int8 not null
  , sCaption varchar(100) not null
  , bIsRead boolean not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idLanguage) references Bkg_Language(id)
  , foreign key (idOriginLanguage) references Bkg_Language(id)
);

create or replace trigger bkg_works_update_row_modified_date
before update on Bkg_Works
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_WorksTranslate (
  id bigserial primary key
  , idWork int8 not null
  , idLanguage int8 not null
  , sCaption varchar(100) not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idWork) references Bkg_Works(id) on delete cascade
  , foreign key (idLanguage) references Bkg_Language(id)
);

create or replace trigger bkg_workstranslate_update_row_modified_date
before update on Bkg_WorksTranslate
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_WorksAuthorsLink (
  id bigserial primary key
  , idWork int8 not null
  , idAuthor int8 not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idWork) references Bkg_Works(id) on delete cascade
  , foreign key (idAuthor) references Bkg_Authors(id) on delete cascade
  , constraint bkg_worksauthorslink_unique_pair unique (idWork, idAuthor)
);

create or replace trigger bkg_worksauthorslink_update_row_modified_date
before update on Bkg_WorksAuthorsLink
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_Series (
  id bigserial primary key
  , sCaption varchar(100) not null
  , idLanguage int8 not null
  , bIsOriginLang boolean not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idLanguage) references Bkg_Language(id)
);

create or replace trigger bkg_series_update_row_modified_date
before update on Bkg_Series
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_SeriesTranslate (
  id bigserial primary key
  , idSeries int8 not null
  , idLanguage int8 not null
  , sCaption varchar(100) not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idSeries) references Bkg_Series(id) on delete cascade
  , foreign key (idLanguage) references Bkg_Language(id)
);

create or replace trigger bkg_seriestranslate_update_row_modified_date
before update on Bkg_SeriesTranslate
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_WorkSeriesLink (
  id bigserial primary key
  , idWork int8 not null
  , idSeries int8 not null
  , sOrder varchar(5) not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idWork) references Bkg_Works(id) on delete cascade
  , foreign key (idSeries) references Bkg_Series(id) on delete cascade
  , constraint bkg_workserieslink_check_numeric_string_constraint check (sOrder ~ '^[0-9]+(\.[0-9]+)?$')
);

create or replace trigger bkg_workserieslink_update_row_modified_date
before update on Bkg_WorkSeriesLink
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_Books (
  id bigserial primary key
  , sCaption varchar(100) not null
  , sISBN varchar(17)
  , idLanguage int8 not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idLanguage) references Bkg_Language(id)
);

create or replace trigger bkg_books_update_row_modified_date
before update on Bkg_Books
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_BooksContent (
  id bigserial primary key
  , idBook int8 not null
  , idWork int8 not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idBook) references Bkg_Books(id) on delete cascade
  , foreign key (idWork) references Bkg_Works(id) on delete cascade
  , constraint bkg_bookscontent_unique_unique_pair unique (idBook, idWork)
);

create or replace trigger bkg_bookscontent_update_row_modified_date
before update on Bkg_BooksContent
for each row
execute function auto_update_dates_trigger_fn();


create table if not exists Bkg_BooksAdditionalISBN (
  id bigserial primary key
  , idBook int8 not null
  , sISBN varchar(17) not null
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , foreign key (idBook) references Bkg_Books(id) on delete cascade
  , constraint bkg_booksadditionalisbn_unique_pair unique (idBook, sISBN)
);

create or replace trigger bkg_booksadditionalisbn_update_row_modified_date
before update on Bkg_BooksAdditionalISBN
for each row
execute function auto_update_dates_trigger_fn();
