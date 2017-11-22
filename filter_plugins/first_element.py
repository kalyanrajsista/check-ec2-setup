#!/usr/bin/env python


def first_element(a_list):
    return a_list[0]


class FilterModule(object):
    def filters(self):
        return {'first_element': first_element}
