class Bestiary

    attr_accessor :beasts

    def initialize()
        @beasts = []
    end

    def get_string_input(output_request)
        puts output_request
        gets.chomp
    end

    def add_entry
        name = get_string_input("Please enter the name: ")
        description = get_string_input("Enter the description for this creature: ")
        newEntry = {name: name, description: description}
        @beasts << newEntry
    end

    def edit_entry_known(entry)
        newDescription = get_string_input("Please write a new description for this entry")
        # sanity check input
        if newDescription = ""
            return nil
        end

        # if input is good set the entry
        entry[:description] = newDescription
    end

    def edit_entry_unknown
        entry = find_entry()
        # sanity check entry
        puts entry
        edit_entry_known(entry)
        puts entry
    end

    def find_entry
        searchTags = get_string_input("What are you looking for?")
        tags = searchTags.split(", ")

        @beasts.each do |beast| 
            tags.each do |tag| 
                if tag == beast[:name]
                    puts beast
                    return beast
                end
            end
        end
    end

end

a = Bestiary.new()
a.add_entry()

a.beasts.each do |thing|
    puts thing
end

a.edit_entry_unknown

