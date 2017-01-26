# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

def commen_pods
    pod 'PromiseKit', '~> 4.0'
    pod 'PromiseKit/Alamofire'
    pod 'Alamofire', '~> 4.0'
    pod 'Kanna', '~> 2.1.0'
end

target 'TheEhenTool' do
    # Comment the next line if you're not using Swift and don't want to use dynamic
    use_frameworks!
    # Pods for TheEhenTool
    commen_pods

    target 'TheEhenToolUITests' do
        inherit! :search_paths
        # Pods for testing
        commen_pods
    end

    target 'TheEhenToolTests' do
        inherit! :search_paths
        commen_pods
    end
end
