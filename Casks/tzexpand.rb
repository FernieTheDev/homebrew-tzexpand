cask "tzexpand" do
  version "0.4.4"
  sha256 "703bc4d4ad08f4f3d8cfe122e6dda100e0db805ebed2d8cbd010d58fafb413bc"

  url "https://github.com/ferniethedev/homebrew-tzexpand/releases/download/v#{version}/TZExpand-#{version}.zip"
  name "TZExpand"
  desc "Hotkey timezone expander for any macOS text input"
  homepage "https://github.com/ferniethedev/homebrew-tzexpand"

  app "TZExpand.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/TZExpand.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/dev.fernie.tzexpand.plist",
  ]

  caveats <<~EOS
    TZExpand needs Accessibility permission to read selected text and paste
    expansions. After first launch, grant access in:

        System Settings → Privacy & Security → Accessibility

    Default hotkey: Control + Option + T  (configure in Settings).
  EOS
end
