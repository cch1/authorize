module Authorize
  module Redis
    # Support foreign keys that reference Redis::Base-like models.
    module ModelReference
      # Load the model whose key is held in the given string key.
      def load_reference(key, klass)
        model_id = klass.db.get(key)
        model_id && klass.load(model_id)
      end

      def set_reference(key, model)
        String.db.set(key, model.id)
      end
      module_function :load_reference, :set_reference
    end
  end
end