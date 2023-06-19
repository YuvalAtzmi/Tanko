
/**/
LINK INVOICES TO :$.PAR ;
GOTO 9988 WHERE :RETVAL <= 0 ;
/**/
:ZTAN_IV = 0 ;
:ZTAN_CUSTNAME = '' ;
:ZYUV_CUST = 0 ;
SELECT INVOICES.IV,
INVOICES.IVNUM,
INVOICES.CUST
INTO :ZTAN_IV,:ZTAN_CUSTNAME,:ZYUV_CUST
FROM INVOICES
WHERE IV <> 0 ;
/**/
UNLINK INVOICES ;
/**/
SELECT ORIG.IVNUM INTO :ZTAN_CUSTNAME
FROM INVOICES ORIG
WHERE IV = :ZTAN_IV ;
/**/
GOTO 9988 WHERE :ZTAN_IV = 0 ;
/*** CHECK IF CUSTOMER RECEIVE ENGLISH INVOICE **/
:ENGINV = '' ;
/**/
SELECT
CUSTOMERS.SECONDLANGTEXT
INTO :ENGINV
FROM CUSTOMERS
WHERE CUSTOMERS.CUST = :ZYUV_CUST ;
/**/
GOTO 9988 WHERE :ENGINV = 'Y' ;
/**/
/*
SELECT :ENGINV FROM DUMMY TABS 'C:\tmp\eng.txt' ;
*/
/**/
/** YUVAL  GET THE DEBITED ACCOUNT NO AND COMPARE TO CUSTOMER **/
:ZYUV_ACCOUNT = 0 ;
/**/
SELECT
INVOICES.ACCOUNT
INTO :ZYUV_ACCOUNT
FROM INVOICES
WHERE INVOICES.IV = :ZTAN_IV ;
/**/
GOTO 10 WHERE :ZYUV_ACCOUNT = 0 ;
/**/
:ZTAN_EMAIL = '' ;
/**/
SELECT
PHONEBOOK.EMAIL
INTO :ZTAN_EMAIL
FROM PHONEBOOK, CUSTOMERS,ACCOUNTS,INVOICES
WHERE ACCOUNTS.ACCOUNT = INVOICES.ACCOUNT
AND CUSTOMERS.CUSTNAME = ACCOUNTS.ACCNAME
AND PHONEBOOK.CUST = CUSTOMERS.CUST
AND PHONEBOOK.CIVFLAG = 'Y'
AND INVOICES.IV = :ZTAN_IV ;
/**/
GOTO 20 ;
/**/
LABEL 10 ;
/**/
:ZTAN_EMAIL = '' ;
SELECT PHONEBOOK.EMAIL INTO :ZTAN_EMAIL
FROM PHONEBOOK, INVOICES
WHERE INVOICES.PHONE = PHONEBOOK.PHONE
AND   INVOICES.IV = :ZTAN_IV ;
/**/
SELECT CUSTOMERSA.EMAIL INTO :ZTAN_EMAIL
FROM INVOICES, CUSTOMERSA
WHERE INVOICES.IV = :ZTAN_IV
AND   INVOICES.CUST = CUSTOMERSA.CUST
AND   :ZTAN_EMAIL = '' ;
/**/
LABEL 20 ;
/**/
GOTO 9988 WHERE :ZTAN_EMAIL = '' ;
GOTO 9988 WHERE NOT EXISTS(
SELECT 'X'
FROM INVOICES, CUSTOMERS
WHERE INVOICES.IV = :ZTAN_IV
AND   INVOICES.CUST = CUSTOMERS.CUST
AND   CUSTOMERS.EDOCUMENTS = 'Y') ;
/**/
GOTO 9988 WHERE EXISTS(
SELECT 'X'
FROM INVOICES
WHERE INVOICES.IV = :ZTAN_IV
AND   INVOICES.PRINTED <> '\0') ;
/**/
GOTO 9988 WHERE EXISTS(
SELECT 'X'
FROM INVOICES
WHERE INVOICES.IV = :ZTAN_IV
AND   INVOICES.FINAL <> 'Y') ;
/**/
:ZTAN_PRINTFORMAT = 0 ;
SELECT NUM INTO :ZTAN_PRINTFORMAT
FROM ZTAN_SHOWCIVFORMAT
WHERE NUM <> 0
AND   USER = SQL.USER ;
/**/
:ZTAN_EXEC = 0 ;
SELECT EXEC INTO :ZTAN_EXEC
FROM EXEC
WHERE ENAME = 'WWWSHOWCIV'
AND   TYPE = 'P'
;
/******/
/**/
:ZTAN_PRINTFORMAT = (SQL.ENV NOT IN ('parkas','parktes','fc',
'conmart') ?
:ZTAN_PRINTFORMAT : -12) ;
INSERT INTO PRINTFORMAT(EXEC, VALUE)
VALUES (:ZTAN_EXEC
, :ZTAN_PRINTFORMAT) ;
/**/
UPDATE PRINTFORMAT SET VALUE = :ZTAN_PRINTFORMAT
WHERE EXEC = :ZTAN_EXEC
AND USER = SQL.USER
AND :ZTAN_PRINTFORMAT <> 0 ;
/**/
INSERT INTO ZTAN_IVPRINTORIG(USER, IV)
VALUES(SQL.USER, :ZTAN_IV) ;
/**/
:ZTAN_FILENAME = '' ;
:ZTAN_FILENAME = STRCAT('..\..\system\mail\INVOICE','-',
:ZTAN_CUSTNAME,
'.pdf');
/**/
/*
EXECUTE DELWINDOW 'f', :ZTAN_FILENAME ;
*/
LABEL 9001 ;
EXECUTE WINHTML '-d', 'WWWSHOWCIV','','','-v', :ZTAN_IV,
'-signpdf','-pdf', :ZTAN_FILENAME;
/**/
DELETE FROM ZTAN_IVPRINTORIG
WHERE USER = SQL.USER
AND   IV = :ZTAN_IV ;
/**/
:PAR1 = '' ;
SELECT TITLE INTO :PAR1
FROM ENVIRONMENT
WHERE DNAME = SQL.ENV ;
/**/
:ZYUV_CUSTACCOUNT = 0 ;
SELECT
CUST INTO :ZYUV_CUSTACCOUNT
FROM CUSTOMERS
WHERE ACCOUNT = :ZYUV_ACCOUNT
AND :ZYUV_ACCOUNT<>0  ;
/*** SET FINALCUST **/
:ZYUV_FINALCUST = 0 ;
:ZYUV_FINALCUST = (:ZYUV_CUSTACCOUNT > 0 ?
:ZYUV_CUSTACCOUNT : :ZYUV_CUST ) ;
GOTO 7001 WHERE EXISTS(
SELECT
'X'
FROM CUSTOMERS,PHONEBOOK
WHERE CUSTOMERS.CUST = PHONEBOOK.CUST
AND CUSTOMERS.CUST = (:ZYUV_CUSTACCOUNT <> 0  ?
:ZYUV_CUSTACCOUNT : :ZYUV_CUST)
AND PHONEBOOK.ZRON_INVOICE = 'Y') ;
/**/
MAILMSG 5000 TO EMAIL :ZTAN_EMAIL
DATA :ZTAN_FILENAME ;
/**/
SELECT ENTMESSAGE('$', 'P', 5001)
FROM DUMMY
ASCII :$.MMM ;
GOTO 7002 ;
/**/
LABEL 7001 ;
:ZYUV_ORDMAIL = '' ;
SELECT SQL.TMPFILE INTO :ZYUV_ORDMAIL FROM DUMMY ;
LINK GENERALLOAD TO :ZYUV_ORDMAIL ;
/*** CREATE EMAIL FORMAT **/
:TITLE = '' ;
SELECT TITLE INTO :TITLE
FROM ENVIRONMENT
WHERE DNAME = SQL.ENV ;
:ZYUV_SUBJECT = '' ;
:ZYUV_SUBJECT = STRCAT( 'מצ"ב חשבונית מרכזת מחברת' ,:TITLE) ;
:LINE = 0 ;
SELECT LINE INTO :LINE FROM GENERALLOAD ORDER BY 1 DESC ;
INSERT INTO GENERALLOAD(LINE,RECORDTYPE,TEXT1,ZCRE_TEXT1)
VALUES (:LINE + 1,'1',:ZYUV_SUBJECT,:ZTAN_FILENAME);
/**/
:LINE2 = 0 ;
SELECT LINE INTO :LINE2 FROM GENERALLOAD ORDER BY 1 DESC ;
INSERT INTO GENERALLOAD (LINE,RECORDTYPE,TEXT2,CHAR1)
SELECT
SQL.LINE + :LINE2,
'3',
PHONEBOOK.EMAIL,
'T'
FROM PHONEBOOK
WHERE PHONEBOOK.CUST = :ZYUV_FINALCUST
AND PHONEBOOK.ZRON_INVOICE = 'Y' ;
EXECUTE INTERFACE
'ZYUV_OPENPRDMAIL',SQL.TMPFILE,'-L',:ZYUV_ORDMAIL;
/**/
:KEY1 = '' ;
SELECT
GENERALLOAD.KEY1
INTO :KEY1
FROM GENERALLOAD
WHERE RECORDTYPE = '1'
AND LOADED = 'Y' ;
:ZYUV_ORDSEND = '' ;
SELECT SQL.TMPFILE INTO :ZYUV_ORDSEND FROM DUMMY ;
LINK MAILBOX TO :ZYUV_ORDSEND ;
GOTO 9988 WHERE :RETVAL <= 0 ;
INSERT INTO MAILBOX
SELECT * FROM MAILBOX ORIG
WHERE ITOA(ORIG.MAILBOX) = :KEY1 ;
EXECUTE SENDMAIL :ZYUV_ORDSEND,SQL.TMPFILE ;
UNLINK MAILBOX ;
UNLINK GENERALLOAD ;
LABEL 7002 ;
:$.SNT = 70 ;
/**/
:$.FFF = '' ;
:$.FFF = :ZTAN_FILENAME ;
/**/
LABEL 9988 ;
