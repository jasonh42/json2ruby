require 'digest/md5'
require 'json'
require 'optparse'
require 'active_support/all'

module JSON2Ruby
  # The RubyWriter class contains methods to output ruby code from a given Entity.
  class FactoryWriter

    def self.to_do
      @@TODO ||= []
    end

    def self.digest(entity, dependency_graph, dag)

      todos = self.to_do

      JSON2Ruby::Entity.entities.keys.each do |k|

        is_string = JSON2Ruby::Entity.entities[k].is_a?(JSON2Ruby::Collection) && JSON2Ruby::Entity.entities[k].ruby_types.keys.include?("0123456789ABCDEF0123456789ABCDEF")

        todos << JSON2Ruby::Entity.entities[k].name if (!JSON2Ruby::Entity.entities[k].is_a?(JSON2Ruby::Primitive) && !is_string)

      end

      # return if !dependency_graph[entity]
      # dependency_graph[entity].each do |ent, v|
      #
      #   if v.is_a?(JSON2Ruby::Collection) && v[:relation]
      #
      #     v[:relational_attrs].each do |rr, v|
      #       if !v.is_a?(JSON2Ruby::Primitive)
      #
      #         todos << rr
      #         self.digest(rr, dependency_graph)
      #       end
      #
      #     end
      #   end
      #
      #
      #   if v.is_a?(JSON2Ruby::Entity) && v[:relation]
      #
      #     todos << rr
      #     self.digest(ent, dependency_graph)
      #
      #   end
      # end


      todos
    end

    def self.camel_case(s)
      return s if s !~ /_/ && s =~ /[A-Z]+.*/
      s.split('_').map{|e| e.capitalize}.join
    end


    # Return a String containing a Ruby class/module definition for the given Entity.
    # Optionally, supply indent to set the indent of the generated code in spaces,
    # and supply a Hash of options as follows:
    # * :modules - Boolean if true, generate Ruby +module+ files instead of classes.
    # * :require - Array of String items, each of which will generate a `require '<x>'` statement for each item
    # * :superclass_name - String, if supplied, the superclass of the class to geneerate
    # * :extend - Array of String items, each of which will generate a `extend '<x>'` statement for each item in the class
    # * :include - Array of String items, each of which will generate a `include '<x>'` statement for each item in the class
    def self.to_code(entity, dependency_graph, indent, options, dag)
      x = ""
      if options.has_key?(:require)
        options[:require].each { |r| x += "require '#{r}'\r\n" }
        x += "\r\n"
      end
      idt = (' '*indent)
      x += "#{(' '*indent)}#{options[:modules] ? "module" : "class"} #{self.camel_case(entity.to_s).upcase_first}Factory"

      x += "\r\n"


      begin
        attributes = JSON2Ruby::Entity.entities[JSON2Ruby::Entity.get_md5(entity)].attributes
      rescue
        attributes = []
      end

      x += attributes_to_ruby(entity, indent+2, attributes,dependency_graph, dag)
      x += "#{(' '*indent)}end\r\n"
      x
    end

    def self.attributes_to_ruby(entity, indent, attributes, dependency_graph, dag)

      x = "#{" "*indent}def self.build("

      attrs = []
      needed_factories = []
      all_keys = []
      non_fact_keys = []
      factory_keys = []
      attributes.each do |k,v|

        attr_name = k

        if !attrs.include? "#{attr_name}"
          attrs << "#{attr_name}:"
        end

        non_fact_keys << k

        all_keys << k
        if dependency_graph[entity].is_a?(Hash)

          v1 = JSON2Ruby::Entity.find_v(dag, entity, {})
          v2 = JSON2Ruby::Entity.find_v(dag, k, {})

          begin

            dag.add_edge from: v1, to: v2

            dependency_graph[entity].each do |key,v|

              if v.is_a?(Hash)
                if v[:relation] == "has_many"

                  if !v[:relational_attrs].blank?
                    factory_str = "#{key.underscore} = #{key}.map{|item| #{key.camelcase}Factory.build(item)}"
                    needed_factories << factory_str if !needed_factories.include?(factory_str)
                    factory_keys << key.underscore
                    all_keys << key
                  end

                elsif v[:relation] == "has_one" && !v[:relational_attrs].blank?
                  factory_str = "#{key.underscore} = #{key.camelcase}Factory.build(#{key})"
                  needed_factories << factory_str if !needed_factories.include?(factory_str)
                  factory_keys << key.underscore
                  all_keys << key
                end

              end
            end
          rescue
          end
        else
          #puts v
          #puts 'whatis key'
        end

      end
      all_keys.uniq!


      create_string = "#{entity.camelcase}.new(#{self.create_stuff(all_keys, factory_keys).join(",")}\r\n#{" "*4})"
      attr_string = self.apply_margins(attrs, x)
      needed_factory_string = needed_factories.to_a.join("\r\n#{" "*2*indent}")

      x += attr_string


      x += ")"
      x += "\r\n"
      x += "#{" "*2*indent}#{needed_factory_string}\r\n"

      for attr in non_fact_keys do
        x += "#{" "*2*indent}#{attr.underscore} = #{attr}\r\n" if !factory_keys.include? attr.underscore
      end
      x += "#{" "*2*indent}#{create_string}\r\n"

      x += "\r\n#{" "*indent}end"
      x += "\r\n"
      x
    end

    def self.create_stuff(keys, factory_keys)
      f = []
      for key in keys do
        f << "\r\n#{" "*6}#{key.underscore}:#{key.underscore}"

      end
      f
    end

    def self.apply_margins(attrs, constructor)
      attr_string = ""
      curr = ""

      for str in attrs do
        curr += str
        if (curr.size + str.size + constructor.size) > 90
          attr_string += "\r\n#{' '*constructor.size}"
          curr = ''
        end
        attr_string += str + ', '

      end

      attr_string = attr_string.sub(/, $/, '')
    end

  end
end