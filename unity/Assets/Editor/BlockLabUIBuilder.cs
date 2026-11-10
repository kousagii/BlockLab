using System;
using System.IO;
using UnityEditor;
using UnityEditor.Events;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;
using TMPro;
using UnityEngine.TextCore.LowLevel;

public static class BlockLabUIBuilder
{
    private static TMP_FontAsset _font;
    private static Sprite _rounded;
    private static SandboxUIController _ui;
    private static readonly Vector2 Zero=Vector2.zero, One=Vector2.one;
    public static void Ensure(LoadManager loader, SaveManager save, SelectionManager selection)
    {
        _font=Font();
        _rounded=RoundedSprite();
        _ui=loader.GetComponent<SandboxUIController>();
        if(_ui!=null && _ui.canvas!=null) {
            foreach(var graphic in _ui.canvas.GetComponentsInChildren<Graphic>(true))
                if(graphic.GetComponent<CanvasRenderer>()==null)graphic.gameObject.AddComponent<CanvasRenderer>();
            RailIcons(); GridMaterial();
            return;
        }
        // Replace the obsolete canvas only after preserving the scene's non-UI managers.
        var old=GameObject.Find("Canvas");
        if(old!=null) UnityEngine.Object.DestroyImmediate(old);
        var hierarchy=loader.GetComponent<HierarchyManager>() ?? loader.gameObject.AddComponent<HierarchyManager>();
        var properties=loader.GetComponent<PropertiesUIManager>() ?? loader.gameObject.AddComponent<PropertiesUIManager>();
        _ui=loader.GetComponent<SandboxUIController>() ?? loader.gameObject.AddComponent<SandboxUIController>();
        _ui.propertiesManager=properties;
        var canvasObject=new GameObject("Canvas",typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));
        var canvas=canvasObject.GetComponent<Canvas>(); canvas.renderMode=RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder=10;
        canvasObject.GetComponent<CanvasScaler>().uiScaleMode=CanvasScaler.ScaleMode.ConstantPixelSize;
        _ui.canvas=canvas;
        var root=Rect("WorkspaceSafeArea",canvasObject.transform); Fill(root); _ui.safeRoot=root;
        var rail=Panel("ToolRail",root); _ui.rail=rail;
        var railLayout=rail.gameObject.AddComponent<VerticalLayoutGroup>();
        railLayout.padding=new RectOffset(4,4,6,6);railLayout.spacing=4;railLayout.childControlWidth=true;railLayout.childControlHeight=true;
        railLayout.childForceExpandHeight=false;railLayout.childForceExpandWidth=true;
        var shapes=Button("Shapes",rail,"Shapes",14); Size(shapes.gameObject,68); Bind(shapes,_ui.ToggleShapes); _ui.shapesButton=shapes;
        var objects=Button("Objects",rail,"Objects",14); Size(objects.gameObject,68); Bind(objects,_ui.ToggleObjects); _ui.objectsButton=objects;
        var collapse=Button("CollapseTools",rail,"Hide",13);Size(collapse.gameObject,64);Bind(collapse,_ui.CollapseTools);
        var open=Button("OpenTools",root,"Tools",14);Set(open.GetComponent<RectTransform>(),new Vector2(0,1),new Vector2(0,1),new Vector2(8,-68),new Vector2(80,-12));
        Bind(open,_ui.ExpandTools);open.gameObject.SetActive(false);

        var drawer=Panel("ToolDrawer",root);_ui.drawer=drawer;_ui.drawerGroup=drawer.gameObject.AddComponent<CanvasGroup>();
        var title=Text("DrawerTitle",drawer,"Shapes",20);Set(title.rectTransform,new Vector2(0,1),One,new Vector2(16,-60),new Vector2(-64,-8));_ui.drawerTitle=title;
        var close=Button("CloseDrawer",drawer,"×",22);Set(close.GetComponent<RectTransform>(),new Vector2(1,1),One,new Vector2(-60,-60),new Vector2(-8,-8));Bind(close,_ui.CloseDrawer);
        var shapesContent=Scroll("Shapes",drawer,68,12);_ui.shapesContent=shapesContent.gameObject;
        var objectsContent=Scroll("Objects",drawer,68,12);_ui.objectsContent=objectsContent.gameObject;
        var scroll=shapesContent.GetComponentInParent<ScrollRect>();
        string[] labels={"Cube","Triangular\nPrism","Cylinder","Trapezoid","Half\nCylinder"};
        for(int i=0;i<5;i++)
        {
            var row=Panel("Shape"+i,shapesContent,SandboxColorRole.Background);Size(row.gameObject,72);
            var glyph=Rect("ShapePreview",row).gameObject.AddComponent<ShapeGlyph>();glyph.shape=(BlockShapeType)i;glyph.raycastTarget=false;
            Set(glyph.rectTransform,new Vector2(0,.5f),new Vector2(0,.5f),new Vector2(12,-20),new Vector2(52,20));
            Style(glyph.gameObject,SandboxColorRole.Accent);
            var label=Text("ShapeLabel",row,labels[i],16);
            Set(label.rectTransform,Zero,One,new Vector2(64,6),new Vector2(-8,-6));
            var drag=row.gameObject.AddComponent<UIDragItem>();
            drag.blockPrefab=loader.blockPrefabs[i];drag.hierarchyManager=hierarchy;drag.selectionManager=selection;drag.scrollParent=scroll;
        }
        var empty=Text("EmptyObjects",drawer,"Your blocks will\nappear here.",15,SandboxColorRole.Muted);
        Set(empty.rectTransform,Zero,One,new Vector2(20,20),new Vector2(-20,-100));
        _ui.emptyObjects=empty.gameObject;

        var inspector=Panel("BlockProperties",root);_ui.properties=inspector;properties.propertiesPanel=inspector.gameObject;
        var name=Text("BlockName",inspector,"Block",17);Set(name.rectTransform,new Vector2(0,1),One,new Vector2(16,-58),new Vector2(-72,-8));
        properties.blockNameLabel=name;
        var dismiss=Button("CloseProperties",inspector,"×",22);Set(dismiss.GetComponent<RectTransform>(),new Vector2(1,1),One,new Vector2(-60,-56),new Vector2(-8,-8));Bind(dismiss,_ui.CloseProperties);
        var content=Scroll("Properties",inspector,64,12);
        Dimension(content,"Width",properties.OnWidthRadiusChanged,out properties.rowWidthRadius,out properties.widthRadiusLabel,out properties.valWidthRadius,out properties.sliderWidthRadius);
        TMP_Text unused;
        Dimension(content,"Height",properties.OnHeightChanged,out properties.rowHeight,out unused,out properties.valHeight,out properties.sliderHeight);
        Dimension(content,"Length",properties.OnLengthChanged,out properties.rowLength,out unused,out properties.valLength,out properties.sliderLength);
        var colorTitle=Text("ColorTitle",content,"Color",16);Size(colorTitle.gameObject,40);
        var swatches=Rect("ColorSwatches",content);Size(swatches.gameObject,112);
        var grid=swatches.gameObject.AddComponent<GridLayoutGroup>();grid.cellSize=new Vector2(48,48);grid.spacing=new Vector2(10,8);
        grid.constraint=GridLayoutGroup.Constraint.FixedColumnCount;grid.constraintCount=4;
        foreach(var color in new[]{"2858C6","198574","E39817","D65353","8D60BF","F6F8FC","52617A","18243A"})
        {
            var swatch=Button("Paint"+color,swatches,"",14);swatch.GetComponent<SandboxStyle>().enabled=false;
            UnityEngine.Object.DestroyImmediate(swatch.GetComponent<SandboxStyle>());
            Color value=SandboxStyle.Hex(color);swatch.image.color=value;
            var listener=swatch.gameObject.AddComponent<BlockColorAction>();listener.manager=properties;listener.color=value;
            Bind(swatch,listener.Apply);
        }
        var colorButton=Button("MoreColors",content,"More colors",15);Size(colorButton.gameObject,52);Bind(colorButton,properties.ToggleColorPicker);
        var chip=Panel("SelectedColor",colorButton.transform);Set(chip,new Vector2(1,.5f),new Vector2(1,.5f),new Vector2(-40,-14),new Vector2(-12,14));
        UnityEngine.Object.DestroyImmediate(chip.GetComponent<SandboxStyle>());properties.colorPreviewButton=chip.GetComponent<Image>();
        var colorLabel=colorButton.GetComponentInChildren<TMP_Text>();colorLabel.alignment=TextAlignmentOptions.MidlineLeft;colorLabel.rectTransform.offsetMin=new Vector2(12,6);colorLabel.rectTransform.offsetMax=new Vector2(-48,-6);
        var pickerPrefab=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/FlexibleColorPicker/FlexibleColorPicker.prefab");
        var picker=(GameObject)PrefabUtility.InstantiatePrefab(pickerPrefab,content);
        picker.name="ColorPicker";var pickerRect=picker.GetComponent<RectTransform>();pickerRect.localScale=Vector3.one;
        Size(picker,260);properties.colorPickerContainer=picker;properties.fcp=picker.GetComponent<FlexibleColorPicker>();
        foreach(var text in picker.GetComponentsInChildren<UnityEngine.UI.Text>(true))text.font=AssetDatabase.LoadAssetAtPath<Font>("Assets/Fonts/Nunito-Semibold.ttf");
        var delete=Button("DeleteBlock",content,"Delete block",15);Size(delete.gameObject,52);Style(delete.GetComponentInChildren<TMP_Text>().gameObject,SandboxColorRole.Danger);Bind(delete,properties.DeleteBlock);
        hierarchy.itemPrefab=HierarchyPrefab();hierarchy.contentPanel=objectsContent;hierarchy.selectionManager=selection;
        properties.hierarchyManager=hierarchy;selection.uiManager=properties;loader.hierarchyManager=hierarchy;
        save.mainUiCanvas=canvasObject;
        drawer.gameObject.SetActive(false);inspector.gameObject.SetActive(false);
        _ui.objectsContent.transform.parent.gameObject.SetActive(false);
        empty.gameObject.SetActive(false);
        _ui.Layout();
        RailIcons(); GridMaterial();
        EditorUtility.SetDirty(loader);EditorUtility.SetDirty(save);EditorUtility.SetDirty(selection);
        EditorUtility.SetDirty(_ui);EditorUtility.SetDirty(properties);EditorUtility.SetDirty(hierarchy);
    }
    private static void GridMaterial() {
        var plane=GameObject.Find("Plane");if(plane==null)return;
        const string path="Assets/Materials/WorkspaceGrid.mat";
        var material=AssetDatabase.LoadAssetAtPath<Material>(path);
        if(material==null) {
            material=new Material(Shader.Find("BlockLab/Workspace Grid"));AssetDatabase.CreateAsset(material,path);
        }
        plane.GetComponent<Renderer>().sharedMaterial=material;
    }
    private static void RailIcons() {
        foreach(var button in _ui.rail.GetComponentsInChildren<Button>(true)) {
            if(button.transform.Find("ToolIcon")!=null)continue;
            var label=button.GetComponentInChildren<TMP_Text>();
            Set(label.rectTransform,Zero,One,new Vector2(2,4),new Vector2(-2,-36));
            var icon=Rect("ToolIcon",button.transform);
            Set(icon,new Vector2(.5f,1),new Vector2(.5f,1),new Vector2(-12,-30),new Vector2(12,-6));
            if(button==_ui.shapesButton)icon.gameObject.AddComponent<ShapeGlyph>().shape=BlockShapeType.Cube;
            else icon.gameObject.AddComponent<ToolGlyph>().collapse=button.name=="CollapseTools";
            icon.GetComponent<Graphic>().raycastTarget=false;Style(icon.gameObject,SandboxColorRole.Accent);
        }
    }
    private static Sprite RoundedSprite()
    {
        const string path="Assets/Fonts/WorkspacePanel.png";
        var sprite=AssetDatabase.LoadAssetAtPath<Sprite>(path);if(sprite!=null)return sprite;
        const int size=48;const float radius=12;
        var texture=new Texture2D(size,size,TextureFormat.RGBA32,false);
        for(int y=0;y<size;y++)for(int x=0;x<size;x++) {
            float dx=Mathf.Max(radius-x-.5f,x+.5f-(size-radius));
            float dy=Mathf.Max(radius-y-.5f,y+.5f-(size-radius));
            float distance=Mathf.Sqrt(Mathf.Pow(Mathf.Max(dx,0),2)+Mathf.Pow(Mathf.Max(dy,0),2));
            texture.SetPixel(x,y,new Color(1,1,1,Mathf.Clamp01(radius-distance+.5f)));
        }
        texture.Apply();File.WriteAllBytes(path,texture.EncodeToPNG());UnityEngine.Object.DestroyImmediate(texture);
        AssetDatabase.ImportAsset(path);
        var importer=(TextureImporter)AssetImporter.GetAtPath(path);importer.textureType=TextureImporterType.Sprite;
        importer.spriteBorder=new Vector4(12,12,12,12);importer.mipmapEnabled=false;importer.alphaIsTransparency=true;
        importer.SaveAndReimport();return AssetDatabase.LoadAssetAtPath<Sprite>(path);
    }
    private static TMP_FontAsset Font()
    {
        const string path="Assets/Fonts/Nunito SDF.asset";
        var asset=AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(path);
        if(asset!=null)return asset;
        var source=AssetDatabase.LoadAssetAtPath<Font>("Assets/Fonts/Nunito-Semibold.ttf");
        if(source==null)throw new Exception("Bundled Nunito font missing");
        asset=TMP_FontAsset.CreateFontAsset(source,64,8,GlyphRenderMode.SDFAA,1024,1024,AtlasPopulationMode.Dynamic,true);
        asset.name="Nunito SDF";AssetDatabase.CreateAsset(asset,path);
        AssetDatabase.AddObjectToAsset(asset.material,asset);
        foreach(var texture in asset.atlasTextures) if(texture!=null && !AssetDatabase.Contains(texture))AssetDatabase.AddObjectToAsset(texture,asset);
        asset.TryAddCharacters("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?+-/()<>");
        EditorUtility.SetDirty(asset);AssetDatabase.SaveAssets();return asset;
    }
    private static GameObject HierarchyPrefab()
    {
        const string path="Assets/Prefab/WorkspaceObjectRow.prefab";
        var previous=AssetDatabase.LoadAssetAtPath<GameObject>(path);if(previous!=null)return previous;
        var row=Button("WorkspaceObjectRow",null,"",16);Size(row.gameObject,64);
        var label=row.GetComponentInChildren<TMP_Text>();label.alignment=TextAlignmentOptions.MidlineLeft;
        label.text="Block";Fill(label.rectTransform,16);
        var prefab=PrefabUtility.SaveAsPrefabAsset(row.gameObject,path);UnityEngine.Object.DestroyImmediate(row.gameObject);return prefab;
    }
    private static void Dimension(Transform parent,string label,UnityAction<float> action,out GameObject row,out TMP_Text title,out TMP_Text value,out Slider slider)
    {
        var rect=Rect(label+"Row",parent);row=rect.gameObject;Size(row,80);row.AddComponent<SandboxRowSize>().baseHeight=80;
        title=Text(label+"Label",rect,label,15);Set(title.rectTransform,new Vector2(0,1),One,new Vector2(0,-40),new Vector2(-72,0));
        value=Text(label+"Value",rect,"1",15);value.alignment=TextAlignmentOptions.MidlineRight;
        Set(value.rectTransform,new Vector2(1,1),One,new Vector2(-72,-40),Zero);
        var track=Panel(label+"Slider",rect,SandboxColorRole.Border);Set(track,Zero,new Vector2(1,0),new Vector2(0,0),new Vector2(0,40));
        slider=track.gameObject.AddComponent<Slider>();slider.minValue=1;slider.maxValue=20;slider.wholeNumbers=true;
        var fill=Panel("Fill",track,SandboxColorRole.Accent);Fill(fill);slider.fillRect=fill;
        var handle=Panel("Handle",track,SandboxColorRole.Accent);handle.sizeDelta=new Vector2(24,32);slider.handleRect=handle;slider.targetGraphic=handle.GetComponent<Image>();
        UnityEventTools.AddPersistentListener(slider.onValueChanged,action);
    }
    private static RectTransform Scroll(string name,Transform parent,float top,float bottom)
    {
        var root=Rect(name+"Scroll",parent);Fill(root);root.offsetMin=new Vector2(12,bottom);root.offsetMax=new Vector2(-12,-top);
        var viewport=Panel("Viewport",root,SandboxColorRole.Surface);Fill(viewport);viewport.gameObject.AddComponent<RectMask2D>();
        var content=Rect(name+"Content",viewport);content.anchorMin=new Vector2(0,1);content.anchorMax=One;content.pivot=new Vector2(.5f,1);content.sizeDelta=Zero;
        var layout=content.gameObject.AddComponent<VerticalLayoutGroup>();layout.spacing=8;layout.childControlHeight=true;layout.childControlWidth=true;layout.childForceExpandHeight=false;
        content.gameObject.AddComponent<ContentSizeFitter>().verticalFit=ContentSizeFitter.FitMode.PreferredSize;
        var scroll=root.gameObject.AddComponent<ScrollRect>();scroll.viewport=viewport;scroll.content=content;scroll.horizontal=false;scroll.movementType=ScrollRect.MovementType.Clamped;
        return content;
    }
    private static RectTransform Rect(string name,Transform parent)
    {
        var go=new GameObject(name,typeof(RectTransform));if(parent!=null)go.transform.SetParent(parent,false);
        return go.GetComponent<RectTransform>();
    }
    private static RectTransform Panel(string name,Transform parent,SandboxColorRole role=SandboxColorRole.Surface)
    { var rect=Rect(name,parent);var image=rect.gameObject.AddComponent<Image>();image.sprite=_rounded;image.type=Image.Type.Sliced;Style(rect.gameObject,role);return rect; }
    private static TMP_Text Text(string name,Transform parent,string value,float size,SandboxColorRole role=SandboxColorRole.Text)
    {
        var rect=Rect(name,parent);var text=rect.gameObject.AddComponent<TextMeshProUGUI>();
        text.font=_font;text.fontSize=size;text.text=value;text.raycastTarget=false;
        text.alignment=TextAlignmentOptions.MidlineLeft;text.enableWordWrapping=true;
        text.overflowMode=TextOverflowModes.Ellipsis;Style(rect.gameObject,role,size);return text;
    }
    private static Button Button(string name,Transform parent,string label,float size)
    {
        var rect=Panel(name,parent);var button=rect.gameObject.AddComponent<Button>();button.targetGraphic=rect.GetComponent<Image>();
        var text=Text("Label",rect,label,size);Fill(text.rectTransform,6);text.alignment=TextAlignmentOptions.Center;
        var colors=button.colors;colors.highlightedColor=new Color(.85f,.9f,1);colors.pressedColor=new Color(.7f,.8f,1);button.colors=colors;
        return button;
    }
    private static void Style(GameObject go,SandboxColorRole role,float textSize=0)
    { var style=go.GetComponent<SandboxStyle>() ?? go.AddComponent<SandboxStyle>();style.role=role;style.textSize=textSize;style.Apply(false,1); }
    private static void Size(GameObject go,float height) { var size=go.GetComponent<LayoutElement>() ?? go.AddComponent<LayoutElement>();size.minHeight=height;size.preferredHeight=height; }
    private static void Bind(Button button,UnityAction action) { UnityEventTools.AddPersistentListener(button.onClick,action); }
    private static void Fill(RectTransform rect,float margin=0) { Set(rect,Zero,One,new Vector2(margin,margin),new Vector2(-margin,-margin)); }
    private static void Set(RectTransform rect,Vector2 min,Vector2 max,Vector2 lower,Vector2 upper)
    {rect.anchorMin=min;rect.anchorMax=max;rect.offsetMin=lower;rect.offsetMax=upper;}
}
