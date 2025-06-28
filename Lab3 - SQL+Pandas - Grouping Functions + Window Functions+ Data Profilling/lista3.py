import csv

def sprawdz_integralnosc(file):
    reader = csv.DictReader(file)
    print("Nieintegralne wartości:")
    for row in reader:
        try:
            if float(row['Quantity']) * float(row['Price Per Unit']) != float(row['Total Spent']):
                print(row)
                print(f"Blad wartosci: {float(row['Quantity']) * float(row['Price Per Unit'])} != {float(row['Total Spent'])}")
        except:  # dla zlych danych nic nie robimy
            pass
    return



def sprawdz_ceny(file):
    reader = csv.DictReader(file)
    price_dict = {}
    for row in reader:
        if row['Item'] in price_dict:
            if row['Price Per Unit'] not in price_dict[row['Item']]:
                price_dict[row['Item']].append(row['Price Per Unit'])
        else:
            price_dict[row['Item']] = [row['Price Per Unit']]
    for item in price_dict:
        print(item, price_dict[item])
with open('dane_lista3.csv', newline='') as csvfile:
    sprawdz_ceny(csvfile)

from datetime import datetime

def sprawdz_spojnosc_dat(file):
    reader = csv.DictReader(file)
    niepoprawne_daty = []
    for row in reader:
        if (row['Transaction Date'] == "" or row['Transaction Date'] == "UNKNOWN" or row['Transaction Date'] == "ERROR"):
            continue
        else:
            try:
                datetime.strptime(row['Transaction Date'], '%Y-%m-%d')
            except ValueError:
                niepoprawne_daty.append(row['Transaction Date'])
    if niepoprawne_daty:
        print("Niepoprawne daty:")
        for data in niepoprawne_daty:
            print(data)
    else:
        print("Wszystkie daty są poprawne.")


# with open("dane_lista3.csv", newline='') as csvfile:
#     sprawdz_dokladnosc(csvfile)

def sprawdz_spojnosc(file):
    reader = csv.DictReader(file)
    item_dict = {"Item" : [], "Quantity" : [], "Price Per Unit" : [], "Total Spent" : [],
                 "Payment Method" : [], "Location" : []}
    for row in reader:
        for column in row:
            if column != "Transaction Date" and column != "Transaction ID":
                if row[column] not in item_dict[column]:
                    item_dict[column].append(row[column])
    for column in item_dict:
        print(column, item_dict[column])


import csv
import re

def sprawdz_spojnosc_transaction_id(file):
    reader = csv.DictReader(file)
    niepoprawne_id = []
    pattern = re.compile(r'^TXN_\d{7}$') #regular expression dla TXN_0000000
    for row in reader:
        if not pattern.match(row['Transaction ID']):
            niepoprawne_id.append(row['Transaction ID'])
    if niepoprawne_id:
        print("Niepoprawne Transaction ID:")
        for txn_id in niepoprawne_id:
            print(txn_id)
    else:
        print("Wszystkie Transaction ID są poprawne.")

with open('dane_lista3.csv', newline='') as csvfile:
    sprawdz_spojnosc_transaction_id(csvfile)

def sprawdz_poprawnosc_transaction_date(file):
    reader = csv.DictReader(file)
    niepoprawne_daty = []
    current_date = datetime.now()
    for row in reader:
        if row['Transaction Date'] == "" or row['Transaction Date'] == "UNKNOWN" or row['Transaction Date'] == "ERROR":
            continue
        else:
            try:
                transaction_date = datetime.strptime(row['Transaction Date'], '%Y-%m-%d')
                if transaction_date >= current_date or transaction_date.year < 2023:
                    niepoprawne_daty.append(row['Transaction Date'])
            except ValueError:
                niepoprawne_daty.append(row['Transaction Date'])
    if niepoprawne_daty:
        print("Niepoprawne daty:")
        for data in niepoprawne_daty:
            print(data)
    else:
        print("Wszystkie daty są poprawne.")

with open('data_lista3.csv', newline='') as csvfile:
    sprawdz_poprawnosc_transaction_date(csvfile)