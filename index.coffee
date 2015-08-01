

class Policy

    constructor: (policy, hierachy)->

        @lookup = {}
        # role -> resource -> action -> true
        @ancesters = {}
        # role -> [role]

        for resource, actions of policy
            for action, roles of actions
                roles = [roles] unless Array.isArray roles
                for role in roles
                    permitted = true
                    if "!" is role.charAt 0
                        role = role.substr 1
                        permitted = false
                    @lookup[role] = {} unless role of @lookup
                    res2action = @lookup[role]
                    res2action[resource] = {} unless resource of res2action
                    res2action[resource][action] = permitted

        findAncesters = (role)->
            if role of hierachy
                parents = hierachy[role]
                parents = [parents] unless Array.isArray parents
                grandParents = parents.map findAncesters
                parents.concat grandParents...
            else
                []

        for role, _ of hierachy
            @ancesters[role] = findAncesters role unless role of @ancesters

        for role, _ancesters of @ancesters
            for ancester in _ancesters
                for own res,actions of @lookup[ancester]
                    @lookup[role][res] = {} unless res of @lookup[role]
                    action2bool = @lookup[role][res]
                    for own action, permitted of actions
                        action2bool[action] = permitted unless action of action2bool

    query: (role, action, resource)->
        return no unless role of @lookup
        return no unless resource of @lookup[role]
        actions = @lookup[role][resource]
        if action of actions
            actions[action]
        else if "default" of actions
            actions["default"]
        else
            no

    extends: (role, ancester)->
        if role of @ancesters
            ancester in @ancesters[role]


class User

    constructor: (roles, @policy, meta)->
        @roles = if Array.isArray roles then roles else [roles]
        for own key,val of meta
            @[key] = val

    can: (action, resource)->
        @roles.some (x)=> @policy.query x, action, resource

    is: (role)->
        role in @roles or @roles.some (x)=> @policy.extends x, role


can = (args...)-> (req, res, next)->
    if req.user.can args...
        next()
    else
        res.sendStatus 403

module.exports =
    User: User
    Policy: Policy
    can: can
