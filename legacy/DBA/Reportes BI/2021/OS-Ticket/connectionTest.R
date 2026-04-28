library(RMySQL)

mysqlconnection = dbConnect(RMySQL::MySQL(),
                            dbname='ostichet',
                            host='localhost',
                            port=3306,
                            user='root',
                            password='')

dbListTables(mysqlconnection)
