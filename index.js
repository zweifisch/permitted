const flatten = hierachy => {
    const findParents = role =>
          hierachy[role] ? (Array.isArray(hierachy[role])
                            ? [...hierachy[role], ...hierachy[role].map(findParents)]
                            : [hierachy[role], ...findParents(hierachy[role])]) : []
    return new Map(Object.keys(hierachy).map(x => [x, findParents(x)]))
}


class Policy {

    constructor(policy, hierachy={}, root='root') {

        this.root = root

        // resource => action => role => bool
        this.rules = new Map(Object.entries(policy).map(
            ([role, action2roles]) =>
                [role, new Map(Object.entries(action2roles).map(
                    ([action, roles])=>
                        [action, new Map((Array.isArray(roles) ? roles : [roles]).map(
                            role => role.charAt(0) === '!' ? [role.substr(1), false] : [role, true]))]))]))

        // role => [role]
        this.hierachy = flatten(hierachy)
    }

    query(role, action, resource) {
        if (role === this.root) return true
        if (!this.rules.has(resource) || !this.rules.get(resource).has(action)) return false
        const role2bool = this.rules.get(resource).get(action)
        if (role2bool.has(role)) return role2bool.get(role)
        return this.hierachy.has(role) && this.hierachy.get(role).some(role => role2bool.has(role) && role2bool.get(role))
    }

    extends(role, ancester) {
        return this.hierachy.has(role) && this.hierachy.get(role).includes(ancester)
    }
}


class User {

    constructor(roles, policy, meta){
        this.policy = policy
        this.roles = Array.isArray(roles) ? roles : [roles]
        Object.assign(this, meta)
    }

    can(action, resource){
        return this.roles.some(x => this.policy.query(x, action, resource))
    }

    is(role){
        return this.roles.includes(role) || this.roles.some(x=> this.policy.extends(x, role))
    }
}


const can = (...args) => async (ctx, next) => {
    if (!ctx.user || !ctx.user.can) {
        throw Error('ctx.user.can not available')
    }
    if (ctx.user.can(...args)) {
        await next()
    } else {
        ctx.status = 403
    }
}

module.exports = {
    User,
    Policy,
    can,
    flatten
}

