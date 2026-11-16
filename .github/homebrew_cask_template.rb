cask "youkomix" do
  version "VERSION"

  on_macos do
    arch arm: "arm64", intel: "amd64"

    sha256 arm:   "ARM_SHA256",
           intel: "AMD_SHA256"

    url "https://github.com/REPO/releases/download/v#{version}/YoukoMix-#{version}-macos-#{arch}.dmg"
  end

  name "人间之里"
  name "YoukoMix"
  desc "Dedicated cross-platform proxy client for YoukoMix"
  homepage "https://github.com/REPO"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "YoukoMix.app"

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-rd", "com.apple.quarantine", "{{appdir}}/YoukoMix.app"],
        writable_paths: ["YoukoMix.app"],
        writable_base:  :appdir
  end

  uninstall quit: "com.youkomix.client"

  zap trash: [
    "~/Library/Application Support/com.youkomix.client",
    "~/Library/Caches/com.youkomix.client",
    "~/Library/Preferences/com.youkomix.client.plist",
    "~/Library/Saved Application State/com.youkomix.client.savedState",
  ]
end
