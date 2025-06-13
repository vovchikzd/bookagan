insert into Bkg_Authors (idLanguage, sFirstName, sLastName, sCoverName, bIsOriginLang)
select t.id, 'Ханья', 'Янагихара', 'Ханья Янагихара', false
from Bkg_Language t
where t.sISO1 = 'ru';

insert into Bkg_Works (idLanguage, idOriginLanguage, sCaption, bIsRead)
select t.id, t2.id, 'Люди среди деревьев', true
from Bkg_Language t, Bkg_Language t2
where t.sISO1 = 'ru' and t2.sISO1 = 'en';

insert into Bkg_WorksAuthorsLink (idWork, idAuthor)
select t.id, t2.id
from Bkg_Works t, Bkg_Authors t2
where t.sCaption = 'Люди среди деревьев'
  and t2.sCoverName = 'Ханья Янагихара';

insert into Bkg_Books (sCaption, sISBN, idLanguage)
select 'Люди среди деревьев', '978-5-17-102325-6', t.id
from Bkg_Language t
where t.sISO1 = 'ru';

insert into Bkg_BooksContent (idBook, idWork)
select t.id, t2.id
from Bkg_Books t, Bkg_Works t2
where t.sISBN = '978-5-17-102325-6'
  and t2.sCaption = 'Люди среди деревьев';

insert into Bkg_Works (idLanguage, idOriginLanguage, sCaption, bIsRead)
select t.id, t2.id, 'Маленькая жизнь', true
from Bkg_Language t, Bkg_Language t2
where t.sISO1 = 'ru' and t2.sISO1 = 'en';

insert into Bkg_WorksAuthorsLink (idWork, idAuthor)
select t.id, t2.id
from Bkg_Works t, Bkg_Authors t2
where t.sCaption = 'Маленькая жизнь'
  and t2.sCoverName = 'Ханья Янагихара';

insert into Bkg_Books (sCaption, sISBN, idLanguage)
select 'Маленькая жизнь', '978-5-17-097119-0', t.id
from Bkg_Language t
where t.sISO1 = 'ru';

insert into Bkg_BooksContent (idBook, idWork)
select t.id, t2.id
from Bkg_Books t, Bkg_Works t2
where t.sISBN = '978-5-17-097119-0'
  and t2.sCaption = 'Маленькая жизнь';


insert into Bkg_Authors (idLanguage, sFirstName, sLastName, sCoverName, bIsOriginLang)
select t.id, 'Robin', 'Hobb', 'Robin Hobb', true
from Bkg_Language t
where t.sISO1 = 'en';

insert into Bkg_AuthorsTranslate (idAuthor, idLanguage, sFirstName, sLastName, sCoverName)
select t.id, t2.id, 'Робин', 'Хобб', 'Робин Хобб'
from Bkg_Authors t, Bkg_Language t2
where t.sCoverName = 'Robin Hobb' and t2.sISO1 = 'ru';

