db.createUser({
    user: 'wolverine',
    pwd: 'wolverine',
    roles: [
        {
            role: 'readWrite',
            db: 'wolverine'
        }
    ]
})
