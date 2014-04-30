namespace :db do
  desc "Fill database with settings data"
  task populate: :environment do
  	Rhinoart::Setting.create!(name: 'site_name', value: 'RhinoArt (change_me)', descr: 'Site name. Shown on title')
  	Rhinoart::Setting.create!(name: 'disabled_pages', value: '01,02', descr: 'Pages iDs for disable pages')
  	Rhinoart::Setting.create!(name: 'mail_to', value: 'test@test.com', descr: 'Manager email for feedback messages')
  end

end
