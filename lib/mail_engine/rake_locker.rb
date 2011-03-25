module MailEngine
  module RakeLocker
    TRY_TIMES = 4

    def lock_task
      raise "Please pass block." unless block_given?

      if locked?
        puts 'locked!'
        lock
      else
        lock
        yield
        unlock
      end
    end

  private

    def locked?
      # if no convert_files_lock1, not locked
      return false unless FileTest.exist? "#{Rails.root}/tmp/convert_files_lock1"
      # if no convert_files_lock4, return locked
      return true unless FileTest.exist? "#{Rails.root}/tmp/convert_files_lock#{TRY_TIMES}"
      ### tried TRY_TIMES times, found convert_files_lock4 file, unlock it
      unlock_task
      return false
    end

    def lock
      (1..TRY_TIMES).each do |n|
        unless FileTest.exist? "#{Rails.root}/tmp/convert_files_lock#{n}"
          `touch #{Rails.root}/tmp/convert_files_lock#{n}`
          break
        end
      end
    end

    def unlock
      `rm #{Rails.root}/tmp/convert_files_lock*`
    end
  end
end