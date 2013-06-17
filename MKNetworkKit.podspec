Pod::Spec.new do |s|
  s.name     = 'MKNetworkKit'
  s.version  = '0.84'
  s.license  = 'MIT'
  s.summary  = 'Full ARC based Networking Kit for iOS 4+ devices'
  s.homepage = 'https://github.com/MugunthKumar/MKNetworkKit'
  s.author   = { 'MugunthKumar' => 'mknetworkkit@mk.sg' }
  s.source   = { :git => 'https://github.com/blazingcloud/MKNetworkKit.git'}

  files = FileList['MKNetworkKit/*.{h,m}', 'MKNetworkKit/Categories/*.{h,m}']
  s.ios.source_files =  files.dup.exclude(/NSAlert/)
  s.osx.source_files =  files.dup.exclude(/UIAlertView/)
  s.ios.frameworks   =  'CFNetwork', 'Security', 'MobileCoreServices'
  s.osx.frameworks   =  'CoreServices', 'Security'

# Clean paths are deprecated. CocoaPods now cleans unused files by default. Use the `preserve_paths` attribute if needed.
#  s.clean_paths  = 'MKNetworkKit-*', '*-Demo', 'SampleImage.jpg'
  s.requires_arc = true

  def s.copy_header_mapping(from)
    from.sub('MKNetworkKit/', '')
  end

  s.dependency 'Reachability', '~> 3.0'

  def s.post_install(target)
    # Fix an import statement which is used inconsistently in MKNetworkKit
    # TODO create a ticket for this upstream
    header = (pod_destroot + 'MKNetworkKit/MKNetworkKit.h')
    header_contents = header.read.sub('Reachability/Reachability.h', 'Reachability.h')
    header.open('w') do |file|
     file.puts(header_contents)
    end

    # Add MKNetworkKit.h to the prefix header
    prefix_header = config.project_pods_root + target.prefix_header_filename
    prefix_header.open('a') do |file|
      file.puts(%{#ifdef __OBJC__\n#import "MKNetworkKit.h"\n#endif})
    end
  end

  s.license  = { :type => 'MIT',
                 :text => 'MKNetworkKit is licensed under MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.' }

end

