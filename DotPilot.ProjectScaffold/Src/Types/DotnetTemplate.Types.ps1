Add-Type -TypeDefinition @"
public class DotnetLayer
{
    public string Name { get; set; } = "";

    public string Type { get; set; } = "";

    public string ExtraArguments { get; set; } = "";

    public System.Collections.Generic.List<string> Packages { get; set; } = [];

    public System.Collections.Generic.List<string> ProjectReferences
    {
        get;
        set;
    } = [];
}

public class DotnetTemplate
{
    public string SolutionName { get; set; } = "";

    public System.Collections.Generic.List<DotnetLayer> Layers
    {
        get;
        set;
    } = [];
}
"@
