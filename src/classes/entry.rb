require 'json'

class Entry
    attr_accessor :name, :description, :external
    def initialize(name, description, external)
        @name = name
        @description = description
        @external = external
    end

    def to_json opt
        {JSON.create_id => self.class.name, name: @name, description: @description, external: @external}.to_json(opt)
    end

    def self.json_create(data)
        new data["name"], data["description"], data["external"]
    end
end