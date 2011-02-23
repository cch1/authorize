module Authorize
  module Redis
    # Support foreign keys that reference Redis::Base-like models.
    module ModelReference
      # Load the model whose key is held in the given string key.
      def load_reference(key, klass)
        reference = klass.db.get(key)
        reference && klass.load(reference)
      end

      def set_reference(key, model)
        if model
          Authorize::Redis::String.db.set(key, model.id)
        else
          Authorize::Redis::String.db.del(key) && nil
        end
      end
      module_function :load_reference, :set_reference
    end
  end
end