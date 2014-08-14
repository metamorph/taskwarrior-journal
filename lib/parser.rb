# Takes a stream of JSON entries as
# in format produced by the +taskwarrior+ export
# command.
#
# The entries are converted to a sequence of
# Tasks.
#
# filter: modified.after:<date>
#

module TaskWarrior
    module Parser

    class Task
        attr_reader :id,
            :status,
            :description,
            :annotations,
            :project,
            :created_at,
            :updated_at,
            :completed_at

        def initialize
            yield self if block_given?
        end
       
        # Parse data from a taskwarrior entry (a Hash).
        def self.parse(rec)
            Task.new do |t|
                t.instance_eval do
                    @id = rec["id"]
                    @status = rec["status"]
                    @description = rec["description"]
                    @project = rec["project"]
                    @created_at = parse_date(rec["entry"])
                    @updated_at = parse_date(rec["modified"])
                    @completed_at = parse_date(rec["completed"])
                    @annotations = if rec["annotations"] 
                                       rec["annotations"].map {|rec| Annotation.parse(t, rec)}
                                   else
                                       []
                                   end
                end
            end
        end

        # Return a function that delegates to +parse+
        def self.parser
            method(:parse).to_proc
        end

    end

    class Annotation
        attr_reader :task,
            :created_at,
            :description
        def initialize
            yield self if block_given?
        end

        def self.parse(task, rec)
            Annotation.new do |a|
                a.instance_eval do
                    @task = task
                    @created_at = parse_date(rec["entry"])
                    @description = rec["description"]
                end
            end
        end
    end

    # Read JSON elements from the stream
    # and return +Task+ items.
    def parse(io)
        require 'json'
        json = "[" + io.read + "]"
        JSON.parse(json).map(&Task.parser)
    end

    def parse_date(date)
        require 'time'
        Time.parse(date) if date
    end

    end # Parser
end

if __FILE__ == $0
    require 'pp'
    include TaskWarrior::Parser
    pp parse(STDIN)
end
