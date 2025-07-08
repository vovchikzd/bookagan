/* create event trigger for table validation */
create or replace function validate_table_requirements()
returns event_trigger as $$
declare
  r record;
  table_oid oid;
begin
  for r in
    select
      *
    from pg_event_trigger_ddl_commands()
    where lower(command_tag) = lower('create table')
  loop
    table_oid := r.objid;
    
    /* check primary key is id */
    if not exists(
      select 1
      from pg_constraint c
      join pg_attribute a on a.attrelid = c.conrelid
        and a.attnum = any(c.conkey)
      where c.conrelid = table_oid
        and c.contype = 'p'
        and a.attname = 'id'
    ) then
      raise exception 'Primary key "id" is required';
    end if;

    /* check primary key is bigserial */
    if not exists(
      select 1
      from pg_attribute
      where attrelid = table_oid
        and attname = 'id'
        and atttypid = 'int8'::regtype
        and attnotnull
    ) then
      raise exception 'Field "id" is required to be not null and has type int8';
    end if;

    /* check existense of dCreateDate and dUpdateDate */
    if not exists(
      select 1
      from pg_attribute
      where attrelid = table_oid
        and lower(attname) = lower('dcreatedate')
        and atttypid = 'timestamptz'::regtype
        and atthasdef
    ) then
      raise exception 'Field "dCreateDate" (timestamptz) is required';
    end if;

    if not exists(
      select 1
      from pg_attribute
      where attrelid = table_oid
        and lower(attname) = lower('dupdatedate')
        and atttypid = 'timestamptz'::regtype
        and atthasdef
    ) then
      raise exception 'Field "dUpdateDate" (timestamptz) is required';
    end if;
  end loop;
end;
$$ language plpgsql;

create event trigger enforce_table_requirements
on ddl_command_end
execute function validate_table_requirements();


/* create trigger function for date updates */
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
  , ('fr', 'fra', 'French', 'Français')
  , ('de', 'deu', 'German', 'Deutsch')
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
  , unique (idWorkVersion, nOrder)
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
  , unique (idSeries, nOrder)
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
  , sISBN varchar(17) not null unique check (trim(sISBN) != '') -- will be validated inside app
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
);

create or replace trigger bkg_additionalisbn_update_row_modified_date
before update on Bkg_AdditionalIsbn
for each row
execute function auto_update_dates_trigger_fn();


/* create book -> additional isbn link table*/
create table if not exists Bkg_BookAddIsbnLink (
  id bigserial primary key
  , idBook int8 not null references Bkg_Book(id) on delete cascade
  , idAdditionalIsbn int8 not null references Bkg_AdditionalIsbn(id) on delete cascade
  , dCreateDate timestamptz default current_timestamp
  , dUpdateDate timestamptz default current_timestamp
  , unique (idBook, idAdditionalIsbn)
);

create or replace trigger bkg_bookaddisbnlink_update_row_modified_date
before update on Bkg_BookAddIsbnLink
for each row
execute function auto_update_dates_trigger_fn();
