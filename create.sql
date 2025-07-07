/* create trigger function */
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

/* create languages table */
create table if not exists Bkg_Language (
  id bigserial primary key
  , sISO1 varchar(2) not null unique check (trim(sISO1) != '')
  , sISO2 varchar(3) not null unique check (trim(sISO2) != '')
  , sEnglishName varchar(20)
  , sNativeName varchar(20)
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_language_update_row_modified_date
before update on Bkg_Language
for each row
execute function auto_update_dates_trigger_fn();

insert into Bkg_Language (sISO1, sISO2, sEnglishName, sNativeName)
values
  ('en', 'eng', 'English', 'English')
  , ('ru', 'rus', 'Russian', 'Русский')
  , ('fr', 'fre', 'French', 'Français')
  , ('de', 'ger', 'German', 'Deutsch')
  , ('pl', 'pol', 'Polish', 'Polski')
  , ('he', 'heb', 'Hebrew', 'עברית');


/* create persons table */
create table if not exists Bkg_Person (
  id bigserial primary key
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_person_update_row_modified_date
before update on Bkg_Person
for each row
execute function auto_update_dates_trigger_fn();


/* create author table */
create table if not exists Bkg_Author (
  id bigserial primary key
  , sName varchar(100) not null check (trim(sName) != '')
  , bIsPseudonym boolean not null default false
  , idLanguage int8 not null references Bkg_Language(id) on delete restrict
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_author_update_row_modified_date
before update on Bkg_Author
for each row
execute function auto_update_dates_trigger_fn();


/* create person -> author link table */
create table if not exists Bkg_PersonAuthorLink (
  id bigserial primary key
  , idPerson int8 not null references Bkg_Person(id) on delete cascade
  , idAuthor int8 not null references Bkg_Author(id) on delete cascade
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , unique (idPerson, idAuthor)
);

create or replace trigger bkg_personauthorlink_update_row_modified_date
before update on Bkg_PersonAuthorLink
for each row
execute function auto_update_dates_trigger_fn();


/* create work table */
create table if not exists Bkg_Work (
  id bigserial primary key
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_work_update_row_modified_date
before update on Bkg_Work
for each row
execute function auto_update_dates_trigger_fn();


/* create work version table */
create table if not exists Bkg_WorkVersion (
  id bigserial primary key
  , idWork int8 not null references Bkg_Work(id) on delete cascade
  , sTitle varchar(100) not null check (trim(sTitle) != '')
  , idLanguage int8 not null references Bkg_Language(id) on delete restrict
  , bIsRead boolean not null default false
  , bIsOriginal boolean not null default false
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create unique index if not exists unique_original_workversion
on Bkg_WorkVersion(idWork)
where bIsOriginal;

create unique index unique_work_language
on Bkg_WorkVersion(idWork, idLanguage)
where not bIsOriginal;

create or replace trigger bkg_workversion_update_row_modified_date
before update on Bkg_WorkVersion
for each row
execute function auto_update_dates_trigger_fn();


/* create table for multy book works */ 
create table if not exists Bkg_WorkVolume (
  id bigserial primary key
  , idWorkVersion int8 references Bkg_WorkVersion(id) not null
  , nOrder numeric(6, 3) not null
  , sVolumeTitle varchar(100) -- null or '' for one volume versions, then i can use coalesce(nullif(sVolumeTitle, ''), sTitle)
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_workvolume_update_row_modified_date
before update on Bkg_WorkVolume
for each row
execute function auto_update_dates_trigger_fn();


/* create work version -> author link */
create table if not exists Bkg_WorkAuthorLink (
  id bigserial primary key
  , idWork int8 not null references Bkg_Work(id) on delete cascade
  , idAuthor int8 not null references Bkg_Author(id) on delete cascade
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , unique (idWork, idAuthor)
);

create or replace trigger bkg_workauthorlink_update_row_modified_date
before update on Bkg_WorkAuthorLink
for each row
execute function auto_update_dates_trigger_fn();


/* create series table */
create table if not exists Bkg_Series (
  id bigserial primary key
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_series_update_row_modified_date
before update on Bkg_Series
for each row
execute function auto_update_dates_trigger_fn();


/* create series version table */
create table if not exists Bkg_SeriesVersion (
  id bigserial primary key
  , idSeries int8 not null references Bkg_Series(id) on delete cascade
  , idLanguage int8 not null references Bkg_Language(id) on delete restrict
  , sTitle varchar(100) not null check (trim(sTitle) != '')
  , bIsOriginal boolean not null default false
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create unique index if not exists unique_original_seriesversion
on Bkg_SeriesVersion(idSeries)
where bIsOriginal;

create unique index unique_series_language
on Bkg_SeriesVersion(idSeries, idLanguage)
where not bIsOriginal;

create or replace trigger bkg_seriesversion_update_row_modified_date
before update on Bkg_SeriesVersion
for each row
execute function auto_update_dates_trigger_fn();


/* create work version -> series version link table */
create table if not exists Bkg_WorkSeriesLink (
  id bigserial primary key
  , idWork int8 not null references Bkg_Work(id) on delete cascade
  , idSeries int8 not null references Bkg_Series(id) on delete cascade
  , nOrder numeric(6, 3) not null check (nOrder > 0)
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , unique (idWork, idSeries)
);

create or replace trigger bkg_workserieslink_update_row_modified_date
before update on Bkg_WorkSeriesLink
for each row
execute function auto_update_dates_trigger_fn();


/* create book table */
create table if not exists Bkg_Book (
  id bigserial primary key
  , sTitle varchar(100) not null check (trim(sTitle) != '')
  , sISBN varchar(17) unique check (sISBN is null or trim(sISBN) != '') -- will be validated inside app
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_book_update_row_modified_date
before update on Bkg_Book
for each row
execute function auto_update_dates_trigger_fn();


/* create content table */
create table if not exists Bkg_BookContent (
  id bigserial primary key
  , idBook int8 not null references Bkg_Book(id) on delete cascade
  , idWorkVolume int8 not null references Bkg_WorkVolume(id) on delete cascade
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , unique (idBook, idWorkVolume)
);

create or replace trigger bkg_bookcontent_update_row_modified_date
before update on Bkg_BookContent
for each row
execute function auto_update_dates_trigger_fn();


/* create additional isbn table */
create table if not exists Bkg_AdditionalIsbn (
  id bigserial primary key
  , idBook int8 not null references Bkg_Book(id) on delete cascade
  , sISBN varchar(17) not null check (trim(sISBN) != '') -- will be validated inside app
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , unique (idBook, sISBN)
);

create or replace trigger bkg_additionalisbn_update_row_modified_date
before update on Bkg_AdditionalIsbn
for each row
execute function auto_update_dates_trigger_fn();
