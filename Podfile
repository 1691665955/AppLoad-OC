platform :ios, '9.0'

target 'AppLoad-OC' do
  #pod 'HCClangTrace', '~> 1.0.1'
  pod "IQKeyboardManager"
  pod 'AFNetworking', '~> 4.0.1'
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      macho_type = config.build_settings['MACH_O_TYPE']
      #if macho_type == 'staticlib'
        if config.name == 'Debug'
          # 将依赖的pod项目的Other C Flags加上’-fsanitize-coverage=func,trace-pc-guard‘选项
          config.build_settings['OTHER_CFLAGS'] ||= ['$(inherited)', '-fsanitize-coverage=func,trace-pc-guard']
          config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)', '-fsanitize-coverage=func,trace-pc-guard']
        end
      #end
    end
  end
end
