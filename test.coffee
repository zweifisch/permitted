
chai = require 'chai'
chai.should()

{User, Policy} = require './index'

describe 'User', ->

    describe 'policy', ->

        policy = new Policy
            article:
                read: ["user", "editor"]
                write: "editor"
            user:
                create: "admin"

        it 'should check user permission from policy', ->
            user = new User "user", policy
            user.can("read", "article").should.equal yes
            user.can("write", "article").should.equal no

            user = new User "admin", policy
            user.can("create", "user").should.equal yes
            user.can("read", "article").should.equal no

        it 'should identify user', ->
            user = new User "admin", policy
            user.is("admin").should.equal yes
            user.is("editor").should.equal no

            user = new User ["admin", "user"], policy
            user.is("admin").should.equal yes
            user.is("editor").should.equal no
            user.is("user").should.equal yes

        it 'root should be able to do anything', ->
            root = new User "root", policy
            root.can("create", "user").should.equal yes

    describe 'role inheritance', ->

        policy =
            article:
                read: ["user", "editor"]
                write: "editor"
            user:
                manage: "admin"

        hierarchy =
            admin: "editor"
            editor: "user"

        it 'admin should extend editor and user', ->
            admin = new User "admin", new Policy policy, hierarchy
            admin.can("read", "article").should.equal yes
            admin.can("write", "article").should.equal yes
            admin.can("manage", "user").should.equal yes

        it 'editor should extend user', ->
            editor = new User "editor", new Policy policy, hierarchy
            editor.can("read", "article").should.equal yes
            editor.can("manage", "user").should.equal no

        it 'should identify user', ->
            user = new User "admin", new Policy policy, hierarchy
            user.is("admin").should.equal yes
            user.is("editor").should.equal yes
            user.is("user").should.equal yes

            user = new User ["editor"], new Policy policy, hierarchy
            user.is("admin").should.equal no
            user.is("editor").should.equal yes
            user.is("user").should.equal yes

    describe 'negation handling', ->

        policy =
            article:
                read: ["user", "editor"]
                write: ["editor", "!admin"]
            user:
                manage: "admin"

        hierarchy =
            admin: "editor"
            editor: "user"

        user = new User "admin", new Policy policy, hierarchy

        it 'should allow admin to read artile', ->
            user.can("read", "article").should.equal yes

        it 'should not allow admin to write artile', ->
            user.can("write", "article").should.equal no

        it 'should not allow admin to create user', ->
            user.can("manage", "user").should.equal yes

    describe 'custom data', ->

        policy =
            article:
                delete: "admin"

        it 'should attach custom data to user', ->
            user = new User "admin", new Policy(policy), id: "33ae0f1c-00c7-496c-a700-99a02d0da904"
            user.id.should.equal "33ae0f1c-00c7-496c-a700-99a02d0da904"
