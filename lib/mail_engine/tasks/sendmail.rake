require 'mail_engine/rake_locker'
namespace :mail_engine do
  include MailEngine::RakeLocker
  desc "Check mail schedule table and send the scheduled mail."
  task :sendmail => :environment do
    lock_task do
      puts "==== Start sending scheduled mail ===="
      MailEngine::MailSchedule.available.each { |schedule| schedule.sendmail }
      puts "==== End sending scheduled mail ===="
    end
  end
end