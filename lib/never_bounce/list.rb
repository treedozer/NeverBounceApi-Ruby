module NeverBounce
  class List
    attr_accessor :master

    def initialize(master)
      @master = master
    end

    def bulk(**args)
      ParseJob.new(@master.call('/v3/bulk', args))
    end

    def status(job_id)
      ParseStatus.new(@master.call('/v3/status', {:job_id => job_id, :version => '3.1'}))
    end

    def download_valid(job_id)
      download(job_id, valids: 1)
    end

    def download_invalids(job_id)
      download(job_id, invalids: 1, textcodes: 0)
    end

    def download_catchall(job_id)
      download(job_id, catchall: 1)
    end

    def download_disposable(job_id)
      download(job_id, disposable: 1)
    end

    def download_unknown(job_id)
      download(job_id, unknown: 1)
    end

    def download(job_id, **args)
      parameters = {
          job_id:     job_id,
          valids:	    args[:valids],
          invalids:	  args[:invalids],
          catchall:	  args[:catchall],
          disposable:	args[:disposable],
          unknown:	  args[:unknown],
          duplicates:	args[:duplicates],
          textcodes:	args[:textcodes]
      }.delete_if{ |k, v| v.nil? }
      ResponseFile.new(@master.call('/v3/download', parameters))
    end
  end

  class ParseJob
    attr_accessor :success, :job_status, :job_id, :execution_time, :response

    def initialize(response)
      @response       = JSON.parse(response.parsed_response)
      @success        = @response['success']
      @job_status     = @response['job_status']
      @job_id         = @response['job_id']
      @execution_time = @response['execution_time']
    end
  end

  class ParseStatus
    attr_reader :success, :job_id, :status, :input_location, :orig_name, :created, :started, :finished, :file_details,
                :job_details, :execution_time, :response,
                :stats, :total, :processed, :valid, :invalid, :bad_syntax, :catchall, :disposable, :unknown, :duplicates,
                :billable, :job_time

    def initialize(response)
      @response       = JSON.parse(response.parsed_response)
      @stats          = @response['stats']
      @success        = @response['success']
      @job_id         = @response['id']
      @status         = @response['status']
      @input_location = @response['input_location']
      @orig_name      = @response['orig_name']
      @created        = @response['created']
      @started        = @response['started']
      @finished       = @response['finished']
      @file_details   = @response['file_details']
      @job_details    = @response['job_details']
      @execution_time = @response['execution_time']
      @created        = @response['created']

      @total          = @stats['total']
      @processed      = @stats['processed']
      @valid          = @stats['valid']
      @invalid        = @stats['invalid']
      @bad_syntax     = @stats['bad_syntax']
      @catchall       = @stats['catchall']
      @disposable     = @stats['disposable']
      @unknown        = @stats['unknown']
      @duplicates     = @stats['duplicates']
      @billable       = @stats['billable']
      @job_time       = @stats['job_time']
    end

    def get_stats
      @stats
    end

    def pending?
      @status.to_i == 2
    end

    def in_progress?
      @status.to_i == 3
    end

    def is_done?
      @status.to_i == 4
    end

    def is_failed?
      @status.to_i == 5
    end

    def get_status
      if (0..5).to_a.map(&:to_s).include?(@status.to_s)
        case @status.to_s
          when '0'
            'Request has been received but has not started idexing'
          when '1'
            'List is indexing and deduping'
          when '2'
            'List is awaiting user input (Typically skipped for lists submitted via API). Check your credits'
          when '3'
            'List is being processed'
          when '4'
            'List has completed verification'
          when '5'
            'List has failed'
        end
      else
        "Unknown status code: #{@status.inspect}"
      end
    end
  end

  class ResponseFile
    attr_reader :response

    def initialize(response)
      @response = if response.headers['content-disposition'].to_s.index(/attachment;/)
                    response.parsed_response
                  else
                    JSON.parse(response.parsed_response)
                  end
    rescue
      raise DownloadError, response['error_msg']
    end

    def lines
      @lines      ||= @response.split(/[\r\n]+/).uniq.delete_if{|x|x.empty?}
    end

    def valid
      @valid      ||= lines.select{|x|x.index(/.+,valid/)}.map{|x|x.gsub(/,valid/, '').strip}.uniq
    end

    def invalid
      @invalid    ||= lines.select{|x|x.index(/.+,invalid/)}.map{|x|x.gsub(/,invalid/, '').strip}.uniq
    end

    def catchall
      @catchall   ||= lines.select{|x|x.index(/.+,catchall/)}.map{|x|x.gsub(/,catchall/, '').strip}.uniq
    end

    def disposable
      @disposable ||= lines.select{|x|x.index(/.+,disposable/)}.map{|x|x.gsub(/,disposable/, '').strip}.uniq
    end

    def unknown
      @unknown    ||= lines.select{|x|x.index(/.+,unknown/)}.map{|x|x.gsub(/,unknown/, '').strip}.uniq
    end

    def all
      @all        ||= lines.map{|x|x.gsub(/,(valid|invalid|catchall|disposable|unknown)/, '').strip}.uniq
    end

    def email_status(email)
      case true
        when valid.include?(email)
          :valid
        when invalid.include?(email)
          :invalid
        when catchall.include?(email)
          :catchall
        when disposable.include?(email)
          :disposable
        when unknown.include?(email)
          :unknown
        else
          raise UnknownEmail, email
      end
    end
  end
end
