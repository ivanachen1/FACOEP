# -*- coding: utf-8 -*-
"""
Created on Fri Oct 28 18:32:14 2022

@author: Usuario
"""

import mysql.connector

try:
    connection = mysql.connector.connect(host='10.22.0.142',
                                         database='osticket',
                                         user='root',
                                         password='')

    sql_select_Query = "select * from Laptop"
    cursor = connection.cursor()
    cursor.execute(sql_select_Query)
    # get all records
    records = cursor.fetchall()

except mysql.connector.Error as e:
    print("Error reading data from MySQL table", e)
finally:
    if connection.is_connected():
        connection.close()
        cursor.close()
        print("MySQL connection is closed")
        
