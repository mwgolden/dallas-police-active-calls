import boto3
from utils import transform_address


ADDRESS_QUEUE_URL = os.getenv('ADDRESS_QUEUE_URL')
ADDRESS_CACHE_TBL = os.getenv('ADDRESS_CACHE_TABLE')

def get_address_id(address_record):
    address_string = '|'.join(address_record.values())
    return sha1(address_string.encode(encoding='utf-8')).hexdigest()

def check_address_cache(address_id):
    db = boto3.resource('dynamodb')
    cache = db.Table(ADDRESS_CACHE_TBL)
    response = cache.get_item(Key = {'address_id': address_id})
    return response.get('Item')


def unique_addresses(data):
    addresses = [transform_address(record) for record in data]
    unique_addresses = []
    for address in addresses:
        if address not in unique_addresses:
            unique_addresses = unique_addresses + [address]
    return unique_addresses

def query_address_cache(unique_locations):
    db = boto3.resource('dynamodb')
    address_cache = db.Table(ADDRESS_CACHE_TBL)
    batch_keys = {
        address_cache.name: {
            'Keys': [{'address_id': loc['address_id']} for loc in unique_locations]
        }
    }
    response = db.batch_get_item(RequestItems=batch_keys)
    return response


def lambda_handler(event, context):
    flatten_cur_data = [cur_data[id] for id in cur_data.keys()]
    addresses = unique_addresses(flatten_cur_data)
    query_results = query_address_cache(addresses)
    result = set([address['address_id'] for address in query_results['Responses']['address_cache']])
    new_addresses = [addr for addr in addresses if addr['address_id'] not in result]
    if len(new_addresses) > 0:
        enqueue(new_addresses, ADDRESS_QUEUE_URL)