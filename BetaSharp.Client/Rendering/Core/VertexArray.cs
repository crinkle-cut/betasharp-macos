namespace BetaSharp.Client.Rendering.Core;

public class VertexArray : IDisposable
{
    private uint id = 0;
    private bool disposed = false;
    private static bool? _vaoSupported;

    /// <summary>
    /// True if VAOs are supported (GL 3.0+ or ARB_vertex_array_object).
    /// When false, VAO operations become no-ops and vertex attribs must be
    /// configured before each draw call.
    /// </summary>
    public static bool IsSupported
    {
        get
        {
            if (!_vaoSupported.HasValue)
            {
                uint testId = GLManager.GL.GenVertexArray();
                if (testId != 0)
                {
                    GLManager.GL.DeleteVertexArray(testId);
                    _vaoSupported = true;
                }
                else
                {
                    _vaoSupported = false;
                }
            }
            return _vaoSupported.Value;
        }
    }

    public bool IsValid => id != 0 && !disposed;

    public VertexArray()
    {
        if (IsSupported)
        {
            id = GLManager.GL.GenVertexArray();
        }
    }

    public void Bind()
    {
        if (!IsSupported)
            return; // No-op when VAOs aren't available

        if (disposed || id == 0)
        {
            throw new Exception("Attempted to bind invalid VertexArray");
        }

        GLManager.GL.BindVertexArray(id);
    }

    public static void Unbind()
    {
        if (IsSupported)
        {
            GLManager.GL.BindVertexArray(0);
        }
    }

    public void Dispose()
    {
        if (disposed)
        {
            return;
        }

        GC.SuppressFinalize(this);

        if (id != 0)
        {
            GLManager.GL.DeleteVertexArray(id);
            id = 0;
        }

        disposed = true;
    }
}
