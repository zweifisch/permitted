# permitted

[![NPM Version][npm-image]][npm-url]
[![Build Status][travis-image]][travis-url]

role & permission control

## usage

```js
import {User, Policy} from "permitted";

let policy = new Policy({
    article: {
        read: ["user", "editor"],
        write: "editor"
    },
    user: {
        default: "admin"
    }
});

let user = new User("admin", policy);

user.can("read", "article");  // false
user.can("manage", "user");  // true
user.is("admin");  // true
```

### role inheritance

```js
import {User, Policy} from "permitted";

let hierarchy = {
    admin: ["user", "editor"],
    editor: "user"
};
let policy = {
    article: {
        read: "user",
        write: "editor"
    },
    issue: {
        report: ["user", "!admin"]
    }
}
let user = new User("admin", new Policy(policy, hierarchy));

user.is("editor");  // true
user.can("read", "article");  // true
user.can("report", "issue");  // false
```

### attach extra data to user object

```js
let user = new User(["role", "elor"], policy, {id: req.session.id});
console.log(user.id);
```

## middleware

```js
import {User, Policy, can} from permitted;
app.use((req, res, next)=>
    req.user = new User(req.session.roles, new Policy(policy, hierachy));
    next();
);

app.get("article/:id", can("read", "article"), handler);
```

[npm-image]: https://img.shields.io/npm/v/permitted.svg?style=flat
[npm-url]: https://npmjs.org/package/permitted
[travis-image]: https://img.shields.io/travis/zweifisch/permitted.svg?style=flat
[travis-url]: https://travis-ci.org/zweifisch/permitted
