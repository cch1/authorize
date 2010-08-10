db = ::Redis.new.tap {|r| r.select 7}
signature_key = ""
signature = "Authorize Plugin Testing DB" # This is intended to be transparent, not secure.
db.setnx(signature_key, signature) # Set our magic cookie to avoid database clashes.
db_signature = db.get(signature_key)
# This exception is triggered to protect against corruption.
# To re-purpose an existing database, manually re-sign it.  Do not disable this assertion!
raise "Database signature is invalid! #{db_signature}" unless db_signature == signature
Authorize::Redis.db = db