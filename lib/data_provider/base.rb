
module DataProvider

  module Base

    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module ClassMethods

      def provider identifier, opts = {}, &block
        add_provider(identifier, opts, block_given? ? block : nil)
      end

      def data_provider_definitions
        ((@data_provider || {})[:provider_args] || [])
      end

      def has_provider?(identifier)
        !single_provider(identifier).nil?
      end

      def single_provider(id, opts = {})
        args = data_provider_definitions.find{|args| args.first == id}
        return args.nil? ? nil : SingleProvider.new(*args)
      end

      def add(providers_module)
        data = providers_module.instance_variable_get('@data_provider') || {}

        (data[:provider_args] || []).each do |definition|
          add_provider(*definition)
        end
      end

      def add_xml_provider(providers_module, opts = {})
        data = providers_module.instance_variable_get('@data_provider') || {}

        (data[:provider_args] || []).each do |definition|
          definition[0] = [definition[0]].flatten
          definition[0] = [opts[:scope]].flatten.compact + definition[0] if opts[:scope]
          add_provider(*definition)
        end
      end

      private

      def add_provider(identifier, opts = {}, block = nil)
        @data_provider ||= {}
        @data_provider[:provider_args] ||= []
        @data_provider[:provider_args].unshift [identifier, opts, block]
      end
    end # module ClassMethods


    module InstanceMethods

      attr_reader :data

      def initialize(data = {})
        @data = (data.is_a?(Hash) ? data : {})
      end

      def has_provider?(id)
        self.class.has_provider?(id)
      end

      def take(id)
        single_provider = self.class.single_provider(id) #, :data => @data)
        # execute block with the scope of this object
        single_provider ? instance_eval(&single_provider.block) : nil
      end

      def given(param_name)
        data[param_name]
      end

      def give(_data = {})
        return self.class.new(data.merge(_data))
      end

      def give!(_data = {})
        @data = data.merge(_data)
        return self
      end
    end # module InstanceMethods

  end # module Base

end # module DataProvider