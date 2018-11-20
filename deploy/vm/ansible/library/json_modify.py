#!/usr/bin/python

from ansible.module_utils.basic import AnsibleModule

import json

try:
    import jsonpointer
except ImportError:
    jsonpointer = None


def main():
    module = AnsibleModule(
        argument_spec=dict(
            data=dict(required=True, type='dict'),
            pointer=dict(required=True),
            action=dict(required=True,
                        choices=['append', 'extend', 'update']),
            update=dict(type='dict'),
            extend=dict(type='list'),
            append=dict(),
        ),
        supports_check_mode=True,
    )

    if jsonpointer is None:
        module.fail_json(msg='jsonpointer module is not available')

    action = module.params['action']
    data = module.params['data']
    pointer = module.params['pointer']

    if isinstance(data, str):
        data = json.loads(str)

    try:
        res = jsonpointer.resolve_pointer(data, pointer)
    except jsonpointer.JsonPointerException as err:
        module.fail_json(msg=str(err))

    if action == 'append':
        res.append(module.params['append'])
    if action == 'extend':
        res.extend(module.params['extend'])
    elif action == 'update':
        res.update(module.params['update'])

    module.exit_json(changed=True,
                     result=data)


if __name__ == '__main__':
    main()