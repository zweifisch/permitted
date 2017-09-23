const chai = require('chai')
chai.should()

const {User, Policy, flatten} = require('./index')

describe('User', () => {

    describe('policy', () => {

        const policy = new Policy({
            article: {
                read: ['user', 'editor'],
                write: 'editor'
            },
            user: {
                create: 'admin'
            }
        })

        it('should check user permission from policy', () => {
            let user = new User('user', policy)
            user.can('read', 'article').should.equal(true)
            user.can('write', 'article').should.equal(false)

            user = new User('admin', policy)
            user.can('create', 'user').should.equal(true)
            user.can('read', 'article').should.equal(false)
        })

        it('should identify user', () => {
            let user = new User('admin', policy)
            user.is('admin').should.equal(true)
            user.is('editor').should.equal(false)

            user = new User(['admin', 'user'], policy)
            user.is('admin').should.equal(true)
            user.is('editor').should.equal(false)
            user.is('user').should.equal(true)
        })

        it('root should be able to do anything', () => {
            const root = new User('root', policy)
            root.can('create', 'user').should.equal(true)
        })
    })

    describe('role inheritance', () => {

        const policy = {
            article: {
                read: ['user', 'editor'],
                write: 'editor'
            },
            user: {
                manage: 'admin'
            }
        }

        const hierarchy = {
            admin: 'editor',
            editor: 'user'
        }

        it('should flatten', () => {
            flatten({
                a: ['b', 'c', 'f'],
                c: 'd',
                d: ['e']
            }).should.deep.equal(new Map(Object.entries({
                a: ['b', 'c', 'd', 'f'],
                c: ['d', 'e'],
                d: ['e']
            })))
        })

        it('admin should extend editor and user', () => {
            const admin = new User('admin', new Policy(policy, hierarchy))
            admin.can('read', 'article').should.equal(true)
            admin.can('write', 'article').should.equal(true)
            admin.can('manage', 'user').should.equal(true)
        })

        it('editor should extend user', () => {
            const editor = new User('editor', new Policy(policy, hierarchy))
            editor.can('read', 'article').should.equal(true)
            editor.can('manage', 'user').should.equal(false)
        })

        it('should identify user', () => {
            let user = new User('admin', new Policy(policy, hierarchy))
            user.is('admin').should.equal(true)
            user.is('editor').should.equal(true)
            user.is('user').should.equal(true)

            user = new User(['editor'], new Policy(policy, hierarchy))
            user.is('admin').should.equal(false)
            user.is('editor').should.equal(true)
            user.is('user').should.equal(true)
        })

    })

    describe('negation handling', () => {

        const policy = {
            article: {
                read: ['user', 'editor'],
                write: ['editor', '!admin']
            },
            user: {
                manage: 'admin'
            }
        }

        const hierarchy = {
            admin: 'editor',
            editor: 'user'
        }

        const user = new User('admin', new Policy(policy, hierarchy))

        it('should allow admin to read artile', () => user.can('read', 'article').should.equal(true))

        it('should not allow admin to write artile', () => user.can('write', 'article').should.equal(false))

        it('should not allow admin to create user', () => user.can('manage', 'user').should.equal(true))
    })

    describe('custom data', () => {

        const policy = {
            article: {
                delete: 'admin'
            }
        }

        it('should attach custom data to user', () => {
            const user = new User('admin', new Policy(policy), {id: '33ae0f1c-00c7-496c-a700-99a02d0da904'})
            user.id.should.equal('33ae0f1c-00c7-496c-a700-99a02d0da904')
        })
    })
})
