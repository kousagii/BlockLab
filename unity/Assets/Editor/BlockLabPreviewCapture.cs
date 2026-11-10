using System;
using System.IO;
using System.Reflection;
using System.Linq;
using UnityEditor;
using UnityEngine;

// Editor-only previews of the actual scene. These are not Android device captures.
[InitializeOnLoad]
public static class BlockLabPreviewCapture
{
    const string Pending="BlockLab.Preview.Pending", Result="BlockLab.Preview.Result";
    static int _index,_frame;
    static bool _capturing, _prepared;
    static string _path;
    static readonly string[] Names={"rail","shapes","objects","properties","rail","shapes","objects","properties","large-text","colors","move","properties-large","white"};
    static BlockLabPreviewCapture() { EditorApplication.playModeStateChanged+=OnMode; }
    public static void Run() {
        BlockLabBuild.Configure();
        SetSize(390,760);
        SessionState.SetBool(Pending,true);SessionState.SetInt(Result,-1);
        EditorApplication.EnterPlaymode();
    }
    static void SetSize(int width,int height) {
        var assembly=typeof(Editor).Assembly;
        var sizesType=assembly.GetType("UnityEditor.GameViewSizes");
        var singleton=typeof(ScriptableSingleton<>).MakeGenericType(sizesType);
        var sizes=singleton.GetProperty("instance",BindingFlags.Public|BindingFlags.Static|BindingFlags.FlattenHierarchy).GetValue(null);
        var group=sizesType.GetMethod("GetGroup").Invoke(sizes,new object[]{GameViewSizeGroupType.Android});
        var sizeType=assembly.GetType("UnityEditor.GameViewSizeType");
        var size=Activator.CreateInstance(assembly.GetType("UnityEditor.GameViewSize"),
            new object[]{Enum.Parse(sizeType,"FixedResolution"),width,height,"BlockLab preview"});
        group.GetType().GetMethod("AddCustomSize").Invoke(group,new[]{size});
        int index=(int)group.GetType().GetMethod("GetTotalCount").Invoke(group,null)-1;
        var view=EditorWindow.GetWindow(assembly.GetType("UnityEditor.GameView"));
        view.GetType().GetProperty("selectedSizeIndex").SetValue(view,index);
        view.Repaint();
    }
    static void OnMode(PlayModeStateChange mode) {
        if(mode==PlayModeStateChange.EnteredPlayMode && SessionState.GetBool(Pending,false)) {
            SessionState.SetBool(Pending,false);
            _index=0;_capturing=false;_prepared=false;_frame=Time.frameCount+60;
            EditorApplication.update+=Tick;
        }
        if(mode==PlayModeStateChange.EnteredEditMode && SessionState.GetInt(Result,-1)>=0) {
            int result=SessionState.GetInt(Result,1);SessionState.SetInt(Result,-1);
            EditorApplication.delayCall+=()=>EditorApplication.Exit(result);
        }
    }
    static void Tick() {
        if(Time.frameCount<_frame)return;
        try {
            if(_prepared) {
                ScreenCapture.CaptureScreenshot(_path);
                _prepared=false;_capturing=true;_frame=Time.frameCount+10;
                return;
            }
            if(_capturing) {
                if(!File.Exists(_path))return;
                Debug.Log("BLOCKLAB_PREVIEW: "+_path+" "+Screen.width+"x"+Screen.height);
                _capturing=false;_index++;
                if(_index>=Names.Length){Finish(0);return;}
            }
            var ui=UnityEngine.Object.FindObjectOfType<SandboxUIController>();
            var selection=UnityEngine.Object.FindObjectOfType<SelectionManager>();
            selection.DeselectCurrent();ui.CloseDrawer();ui.ExpandTools();
            bool dark=_index>=4 && _index!=12;
            if(_index==8 || _index==11)SetSize(320,700);
            if(_index==9 || _index==12)SetSize(390,760);
            ui.SetAppearance("{\"mode\":\""+(dark?"dark":"light")+"\",\"textScale\":"+(_index==8 || _index==11?"2":"1")+",\"pixelRatio\":1}");
            if(_index==0) {
                var loader=ui.GetComponent<LoadManager>();
                loader.BeginSession("{\"sessionId\":\"preview\",\"sceneDataJson\":\"\"}");
                for(int i=0;i<3;i++) {
                    var block=UnityEngine.Object.Instantiate(loader.blockPrefabs[i]).GetComponent<BlockData>();
                    block.EnsureIdentity();block.name=new[]{"Cube 1","Triangular Prism 1","Cylinder 1"}[i];
                    BlockPlacement.TryPlace(block,new Vector3(i*2-2,0,0),1);
                    block.SetColor(new[]{SandboxStyle.Hex("E39817"),SandboxStyle.Hex("2858C6"),SandboxStyle.Hex("198574")}[i]);
                    ui.GetComponent<HierarchyManager>().AddBlockToList(block.gameObject);
                }
            }
            int kind=_index%4;
            if(kind==1 || _index==8)ui.ToggleShapes();
            if(kind==2)ui.ToggleObjects();
            if(kind==3 || _index==9 || _index==10)selection.ForceSelectBlock(UnityEngine.Object.FindObjectsOfType<BlockData>().First(b=>b.shapeType==BlockShapeType.Cube));
            if(_index==9)ui.ShowColors();
            if(_index==10)ui.ShowMove();
            if(_index==12) {
                var white=UnityEngine.Object.FindObjectsOfType<BlockData>().First(b=>b.shapeType==BlockShapeType.Cube);
                white.SetColor(Color.white);selection.ForceSelectBlock(white);
            }
            string output=Path.GetFullPath(Path.Combine(Application.dataPath,"../../docs/screenshots"));
            Directory.CreateDirectory(output);
            _path=Path.Combine(output,"sandbox-"+Names[_index]+"-"+(dark?"dark":"light")+".png");
            if(File.Exists(_path))File.Delete(_path);
            Canvas.ForceUpdateCanvases();
            _prepared=true;_frame=Time.frameCount+30;
        } catch(Exception e){Debug.LogException(e);Finish(1);}
    }
    static void Finish(int result) {
        EditorApplication.update-=Tick;
        if(result==0)Debug.Log("BLOCKLAB_PREVIEWS_PASSED");
        SessionState.SetInt(Result,result);EditorApplication.ExitPlaymode();
    }
}
