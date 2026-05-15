using UnityEditor;
using System.IO;

namespace OwenTheProgrammer.Tools
{
    public class CgincAssetProcessor : AssetModificationProcessor
    {
        public static void OnWillCreateAsset(string path)
        {
            // The templated file is created, then the meta file is created.
            // Id like the template to come first, then edit the cginc when the meta files created

            // Leave if this files not a cginc meta file
            if(!path.EndsWith(".cginc.meta")) return;

            path = path.Replace(".meta", string.Empty);
            path = Path.GetFullPath(path);

            // Just in case the file doesnt exist for some reason..
            if(!File.Exists(path)) return;

            // Convert the filename to SCREAMING_SNAKE_CASE (yes thats the actual name lol)
            string filename = Path.GetFileNameWithoutExtension(path);
            string macroID = filename.Trim().Replace(' ', '_').ToUpper();

            // String replace all occurances
            string data = File.ReadAllText(path);
            data = data.Replace("#CGINCNAME#", macroID);

            // Aaaaaandddd write.
            File.WriteAllText(path, data);
            AssetDatabase.Refresh();
        }
    }
}