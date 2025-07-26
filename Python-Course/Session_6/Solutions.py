import os
import json
import numpy as np
import pandas as pd
import fastavro
from fastavro import writer, parse_schema

PATH_TO_SALES = "./source_files/sales.csv"
PATH_TO_HOUSES = "./source_files/houses.csv"
PATH_TO_EMPLOYEES = "./source_files/employees.csv"

#Task 1
sales = pd.read_csv(PATH_TO_SALES)
houses = pd.read_csv(PATH_TO_HOUSES)
employees = pd.read_csv(PATH_TO_EMPLOYEES)

#Task 2
names = employees.loc[3:10, ['EMP_FIRST_NAME', 'EMP_LAST_NAME']]
names

#Task 3
amount_by_gender = employees.value_counts('EMP_GENDER')

#Task 4
houses['SQUARE'].fillna(0, inplace=True)

#Task 5
houses['UNIT_PRICE'] = houses['PRICE'] / houses['SQUARE']
houses['UNIT_PRICE'].replace(np.inf, -1, inplace=True)

#Task 6
houses.sort_values(by='PRICE', ascending=False, inplace=True)

# Ensure folder exists
os.makedirs('output_files', exist_ok=True)

# Write directly to file by passing filename
houses.to_json('output_files/task_6.json', orient='records', indent=2)

#Task 7
employees_filtered = employees[
    (employees['EMP_FIRST_NAME'] == 'Vera') &
    (employees['EMP_GENDER'] == 'Female')
]

vera_female_count = len(employees_filtered)
print(vera_female_count)

#Task 8
large_houses = houses[houses['SQUARE'] >= 100]
house_counts = large_houses.groupby(['HOUSE_CATEGORY_ID', 'HOUSE_SUBCATEGORY_ID']).size()

print(house_counts)


#Task 9
employees_filtered_dict = employees_filtered.to_dict('records')
schema = {
    'doc': 'Task_9',
    'name': 'Employee_filtered',
    'type': 'record',
    'fields': [
        {'name': "EMP_ID", "type": "int"},
        {'name': "EMP_FIRST_NAME", "type": "string"},
        {'name': "EMP_LAST_NAME", "type": "string"},
        {'name': "EMP_GENDER", "type": "string"},
        {'name': "EMP_DATE_BIRTH", "type": "string"},
        {'name': "EMP_START_DATE", "type": "string"},
        {'name': "EMP_BRANCH", "type": "float"}
    ],
}

parsed_schema = fastavro.parse_schema(schema)


with open('output_files/task_9.avro', 'wb') as target_file:
    fastavro.writer(target_file, parsed_schema, employees_filtered_dict)


#Task10
average_sales = sales['SALEAMOUNT'].mean() * 0.02

sales['SALEAMOUNT'] = sales['SALEAMOUNT'].apply(lambda sales: sales + average_sales)

#Task11
sales_houses = houses.join(sales.set_index('HOUSE_ID'), on='HOUSE_ID', how = 'left', lsuffix='_sales', rsuffix='_houses')
house_ids_available = sales_houses[sales_houses['PAYMENT_TYPE'].isna()]
only_house_id = house_ids_available['HOUSE_ID']
with open('./output_files/task_11.json', mode='w') as target_file:
    only_house_id.to_json(target_file, orient='records')
house_ids_available = only_house_id.tolist()


