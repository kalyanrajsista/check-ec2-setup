# (c) 2016, Pierre Jodouin <pjodouin@virtualcomputing.solutions>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.
#

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json
import decimal

from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

try:
    import boto3
    from boto3.dynamodb.conditions import Key, Attr
    from botocore.exceptions import ClientError, EndpointConnectionError
    HAS_BOTO3 = True
except ImportError:
    HAS_BOTO3 = False

# Helper class to convert a DynamoDB item to JSON.
class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            if o % 1 > 0:
                return float(o)
            else:
                return int(o)
        return super(DecimalEncoder, self).default(o)


def lookup_table(dynamodb, args):

    api_params = dict(TableName=args[0])
    if len(args) > 1:
        api_params.update(Payload=args[1])

    # execute lambda function
    try:
        table = dynamodb.Table('name')
        results = table.get_item(**api_params)
    except ClientError as e:
        raise AnsibleError('Error reading DynamoDB table {0}: {1}'.format(args[0], e))
    except EndpointConnectionError as e:
        raise AnsibleError('DynamoDB table {0} not found: {1}'.format(args[0], e))

    # The returned Payload is a botocore StreamingBody object. Read all content and convert to JSON.
    if 'Payload' in results:
        payload = json.loads(results['Payload'].read())

    return payload


class LookupModule(LookupBase):

    def run(self, terms, inject=None, **kwargs):

        # validate dependencies
        if not HAS_BOTO3:
            raise AnsibleError('Boto3 is required for the lambda plugin.')

        if len(terms) == 1:
            args = terms[0].split('/')
        else:
            args = terms

        try:
            dynamodb = boto3.resource('dynamodb')

            client = boto3.client('dynamodb')
        except ClientError as e:
            raise AnsibleError("Can't authorize connection - {0}".format(e))
        except EndpointConnectionError as e:
            raise AnsibleError("Connection Error - {0}".format(e))

        response = [lookup_table(dynamodb, args)]

        return response
