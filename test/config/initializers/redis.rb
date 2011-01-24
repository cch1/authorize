Authorize::Redis::Base.logger = Rails.logger
Authorize::Redis::Base.connection_specification = Authorize::Redis::ConnectionSpecification.new({:logger => Rails.logger, :db => 7})
signature_key, signature = "", "Authorize Plugin Testing DB" # This is intended to be transparent, not secure.
Authorize::Redis::Base.db.setnx(signature_key, signature) # Set our magic cookie to avoid database clashes.
db_signature = Authorize::Redis::Base.db.get(signature_key)
# This exception is triggered to protect against corruption.
# To re-purpose an existing database, manually re-sign it.  Do not disable this assertion!
raise "Database signature is invalid! #{db_signature}" unless db_signature == signature