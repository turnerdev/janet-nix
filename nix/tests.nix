pkgs:
{
  binscript-bin =
    let
      src = pkgs.symlinkJoin {
        name = "src";
        paths = [
          (pkgs.writeTextDir "project.janet" ''
            (declare-project :name "myproj")
            (declare-binscript :main "src/test")
          '')
          (pkgs.writeTextDir "src/test" ''
            #!/usr/bin/env janet
            (defn main [& args] (print "binscript-bin"))
          '')
        ];
      };
      pkg = pkgs.mkJanet {
        inherit src;
        name = "test";
        bin = "test";
      };
    in
    pkgs.runCommand "binscript-bin" { } ''
      output=$(${pkg}/bin/test)
      [ "$output" = "binscript-bin" ] || (echo "Unexpected output: $output"; exit 1)
      touch $out
    '';
}
