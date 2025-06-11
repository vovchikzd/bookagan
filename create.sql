create or replace function update_modified_date()
returns trigger as $$
begin
  new.dUpdated = current_timestamp;
  return new;
end;
$$ language plpgsql;


create table if not exists authors (
  id serial primary key
  , sCaption varchar (100)
  , sFirstName varchar(100)
  , sMiddleName varchar(100)
  , sLastName varchar(100)
  , dBirthDate date
  , sOrigLanguage varchar(100)
  , dCreated timestamp with time zone default current_timestamp
  , dUpdated timestamp with time zone default current_timestamp
);

create or replace trigger update_row_modified_date
before update on authors
for each row
execute function update_modified_date();


create table if not exists works (
  id serial primary key
  , sCaption varchar(100) not null
  , sOrigCaption varchar(100) not null
  , sWriteLang varchar(100) not null
  , dCreated timestamp with time zone default current_timestamp
  , dUpdated timestamp with time zone default current_timestamp
);

create or replace trigger update_row_modified_date
before update on works
for each row
execute function update_modified_date();


create table if not exists work_authors (
  id serial primary key
  , idWork integer not null
  , idAuthor integer not null
  , dCreated timestamp with time zone default current_timestamp
  , dUpdated timestamp with time zone default current_timestamp
  , foreign key (idWork) references works(id) on delete cascade
  , foreign key (idAuthor) references authors(id) on delete cascade
);

create or replace trigger update_row_modified_date
before update on work_authors
for each row
execute function update_modified_date();


create table if not exists books (
  id serial primary key
  , sCaption varchar(100)
  , dCreated timestamp with time zone default current_timestamp
  , dUpdated timestamp with time zone default current_timestamp
);

create or replace trigger update_row_modified_date
before update on books
for each row
execute function update_modified_date();


create table if not exists book_works (
  id serial primary key
  , idBook integer not null
  , idWork integer not null
  , dCreated timestamp with time zone default current_timestamp
  , dUpdated timestamp with time zone default current_timestamp
  , foreign key (idWork) references works(id) on delete cascade
  , foreign key (idBook) references books(id) on delete cascade
);

create or replace trigger update_row_modified_date
before update on book_works
for each row
execute function update_modified_date();
