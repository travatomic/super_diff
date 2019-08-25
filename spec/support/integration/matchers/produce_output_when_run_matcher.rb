module SuperDiff
  module IntegrationTests
    def produce_output_when_run(output)
      ProduceOutputWhenRunMatcher.new(output)
    end

    class ProduceOutputWhenRunMatcher
      PROJECT_DIRECTORY = Pathname.new("../../../../../").expand_path(__FILE__)
      TEMP_DIRECTORY = PROJECT_DIRECTORY.join("tmp")

      def initialize(expected_output)
        @expected_output =
          expected_output.
            strip.
            split(/(\n+)/).
            map { |line| line =~ /\n+/ ? line : (" " * 7) + line }.
            join
      end

      def matches?(test)
        @test = test.strip
        TEMP_DIRECTORY.mkpath
        actual_output.include?(expected_output)
      end

      def failure_message
        "Expected test to produce output, but it did not.\n\n" +
          "Expected output:\n\n" +
          CommandRunner::OutputHelpers.divider("START") +
          expected_output + "\n" +
          CommandRunner::OutputHelpers.divider("END") +
          "\n" +
          "Actual output:\n\n" +
          CommandRunner::OutputHelpers.divider("START") +
          actual_output + "\n" +
          CommandRunner::OutputHelpers.divider("END")
      end

      private

      attr_reader :expected_output, :test

      def actual_output
        @_actual_output ||=
          CommandRunner.run("rspec", tempfile.to_s).output.strip
      end

      def tempfile
        @_tempfile =
          TEMP_DIRECTORY.join("acceptance_spec.rb").
            tap { |tempfile| tempfile.write(program) }
      end

      def program
        <<~PROGRAM
          $LOAD_PATH.unshift("#{PROJECT_DIRECTORY.join("lib")}")
          $LOAD_PATH.unshift("#{PROJECT_DIRECTORY}")
          require "super_diff/rspec"
          begin
            require "pry-byebug"
          rescue LoadError
            require "pry-nav"
          end
          require "spec/support/person"
          require "spec/support/person_diff_formatter"
          require "spec/support/person_operation_sequence"
          require "spec/support/person_operational_sequencer"

          SuperDiff::RSpec.configure do |config|
            config.extra_operational_sequencer_classes << SuperDiff::Test::PersonOperationalSequencer
            config.extra_diff_formatter_classes << SuperDiff::Test::PersonDiffFormatter
          end

          RSpec.describe "test" do
            it "passes" do
          #{reindent(test, level: 2)}
            end
          end
        PROGRAM
      end

      def reindent(code, level: 0)
        code.strip.split("\n").map { |line| ("  " * level) + line }.join("\n")
      end
    end
  end
end