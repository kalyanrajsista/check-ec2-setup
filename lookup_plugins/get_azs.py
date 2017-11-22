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

from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

import os
import time
import pickle

try:
    import boto3
    from botocore.exceptions import ClientError, EndpointConnectionError

    HAS_BOTO3 = True
except ImportError:
    HAS_BOTO3 = False


class LookupModule(LookupBase):
    """
    Return a list of availability zones for a region.
    """

    def __init__(self, **kwargs):

        self.cache_dir = os.path.join(os.environ['HOME'], '.azs_cache')
        self.cache_time = 30

        super(LookupModule, self).__init__(**kwargs)

    def check_cache(self, file_name):

        now = int(time.time())
        data = None

        if os.path.isfile(file_name):
            if (now - int(os.path.getmtime(file_name))) < self.cache_time:
                fh = open(file_name, 'r')
                data = pickle.load(fh)

        return data

    def get_azs(self, region=None):

        az_cache = os.path.join(self.cache_dir, '{}-azs'.format(region or 'default'))
        az_names = self.check_cache(az_cache)

        if not az_names:
            try:
                azs = boto3.client('ec2', region_name=region).describe_availability_zones()['AvailabilityZones']
            except ClientError, e:
                raise AnsibleError(e.message)
            except EndpointConnectionError:
                raise AnsibleError('Region invalid or unavailable: {}'.format(region))

            az_names = [az['ZoneName'] for az in azs if az['State'] == 'available']

            try:
                fh = open(az_cache, 'w')
                pickle.dump(az_names, fh)
            except Exception, e:
                raise AnsibleError('Cache error: {}'.format(e.message))

        return az_names

    def run(self, terms=None, inject=None, **kwargs):

        # validate dependencies
        if not HAS_BOTO3:
            raise AnsibleError('Boto3 is required for the get_azs plugin.')

        # create cache folder if needed
        if not os.path.isdir(self.cache_dir):
            os.mkdir(self.cache_dir)

        region = terms[0] if len(terms) > 0 else None

        return self.get_azs(region)
