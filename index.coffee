
# [role] -> role:bool
roles2map = (roles)->
    ret = {}
    roles = [roles] unless Array.isArray roles
    for role in roles
        if role.charAt(0) is "!"
            ret[role.substr 1] = no
        else
            ret[role] = yes
    ret


class Policy

    constructor: (policy, hierachy, @root="root")->

        # role : [role]
        @ancesters = {}

        # resource : action : role : bool
        @rules = {}

        for resource, action2roles of policy
            action2roles2bool = {}
            for action, roles of action2roles
                action2roles2bool[action] = roles2map roles
            @rules[resource] = action2roles2bool

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

    query: (role, action, resource)->
        return yes if role is @root
        return no unless resource of @rules
        return no unless action of @rules[resource]
        role2bool = @rules[resource][action]
        return role2bool[role] if role of role2bool
        if role of @ancesters
            for r in @ancesters[role]
                return role2bool[r] if r of role2bool

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
    if req.user?.can? args...
        next()
    else
        res.sendStatus 403

module.exports =
    User: User
    Policy: Policy
    can: can
