using System;

// Session-local UI state. Never serialized into a learner's geometry.
public static class WorkspaceState
{
    public static bool Dirty { get; private set; }
    public static int Revision { get; private set; }
    public static event Action Changed;
    public static void Edit() { Revision++; Dirty = true; Changed?.Invoke(); }
    public static void Reset() { Revision = 0; Dirty = false; Changed?.Invoke(); }
    public static void Saved(int revision) { if (revision == Revision) Dirty = false; Changed?.Invoke(); }
    public static void Refresh() { Changed?.Invoke(); }
}
