#!/usr/bin/env python


def list_slice(a_list, start, end):
    return a_list[start:end]


class FilterModule(object):
    def filters(self):
        return {'list_slice': list_slice}
