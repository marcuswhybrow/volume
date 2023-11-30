{
  description = "Adjust volume and notify";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs: let 
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    pamixer = "${pkgs.pamixer}/bin/pamixer";
    unmuteOnChange = true;
    step = 5;
    muteArgs = if unmuteOnChange then "--unmute" else "";
  in {
    packages.x86_64-linux.volume = pkgs.writeShellScriptBin "volume" ''
      delta=$(case $(${pamixer} --get-volume) in
        0) echo 1;;
        1) echo ${toString (step - 1)};;
        *) echo ${toString step};;
      esac)

      case $1 in
        up)          ${pamixer} ${muteArgs} --increase $delta;;
        down)        ${pamixer} ${muteArgs} --decrease $delta;;
        toggle-mute) ${pamixer} --toggle-mute;;
      esac

      isMuted=$(${pamixer} --get-mute)
      volume=$(${pamixer} --get-volume)

      ${pkgs.libnotify}/bin/notify-send \
        --app-name changeVolume \
        --urgency low \
        --expire-time 2000 \
        --icon audio-volume-$([[ $isMuted == true ]] && echo muted || echo high) \
        --hint string:x-dunst-stack-tag:volume \
        $([[ $isMuted == false ]] && echo "--hint int:value:$volume") \
        "$([[ $isMuted == false ]] && echo "Volume: $volume%" || echo "Volume Muted")"
    '';

    packages.x86_64-linux.default = inputs.self.packages.x86_64-linux.volume;
  };
}
