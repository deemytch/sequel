# frozen-string-literal: true

module Sequel
  module Plugins
    # The association_multi_add_remove plugin allows adding and removing multiple
    # associated objects in a single method call.  By default Sequel::Model defines
    # singular <tt>add_*</tt> and <tt>remove_*</tt> methods that operate on a single
    # associated object, this adds plural forms that operate on multiple associated
    # objects.  Example:
    #
    #   artist.albums # => [album1]
    #   artist.add_albums([album2, album3])
    #   artist.albums # => [album1, album2, album3]
    #   artist.remove_albums([album3, album1])
    #   artist.albums # => [album2]
    #
    # It can handle all situations that the normal singular methods handle, but there is
    # no attempt to optimize behavior, so using these methods will not improve performance.
    #
    # The add/remove methods defined by this plugin use a transaction, so if one add/remove
    # fails and raises an exception, all adds/removes will be rolled back.  If you are using
    # database sharding and want to save to a specific shard, call Model#set_server to set
    # the server for this instance, as the transaction will be opened on that server.
    #
    # You can customize the method names used for adding/removing multiple associated
    # objects using the :multi_add_method and :multi_remove_method association options.
    #
    # Usage:
    #
    #   # Allow adding/removing multiple associated objects in a single call for all
    #   # model subclass instances (called before loading subclasses):
    #   Sequel::Model.plugin :association_multi_add_remove
    #
    #   # Allow adding/removing multiple associated objects in a single call for Album
    #   # instances (called before defining associations in the class):
    #   Album.plugin :association_multi_add_remove
    module AssociationMultiAddRemove
      module ClassMethods
        # Define the methods use to add/remove multiple associated objects in a single
        # method call.
        def def_association_instance_methods(opts)
          super

          if opts[:adder]
            add_method = opts[:add_method]
            multi_add_method = opts[:multi_add_method] || :"add_#{opts[:name]}"
            if add_method != multi_add_method
              association_module_def(multi_add_method, opts) do |objs, *args|
                db.transaction(:server=>@server){objs.map{|obj| send(add_method, obj, *args)}.compact}
              end
            end
          end

          if opts[:remover]
            remove_method = opts[:remove_method]
            multi_remove_method = opts[:multi_remove_method] || :"remove_#{opts[:name]}"
            if remove_method != multi_remove_method
              association_module_def(multi_remove_method, opts) do |objs, *args|
                db.transaction(:server=>@server){objs.map{|obj| send(remove_method, obj, *args)}.compact}
              end
            end
          end
        end
      end
    end
  end
end
