import bcrypt

def hash(password):
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
