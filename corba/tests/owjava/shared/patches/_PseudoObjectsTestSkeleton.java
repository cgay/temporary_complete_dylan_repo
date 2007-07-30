//
// Java generated by the OrbixWeb IDL compiler 
//

package shared;





public abstract class _PseudoObjectsTestSkeleton 
    extends org.omg.CORBA.DynamicImplementation 
{
    protected _PseudoObjectsTestSkeleton()
    {
        super();
    }

    public String[] _ids()
    {
        return _PseudoObjectsTestStub._interfaces;
    }
    public void invoke(org.omg.CORBA.ServerRequest _req)
    {
        _invoke(_req, this);
    }
    public static void _invoke(org.omg.CORBA.ServerRequest _req,_PseudoObjectsTestSkeleton _obj)
    {
        String _opName = _req.op_name();
        org.omg.CORBA.Any _ret = _obj._orb().create_any();
        org.omg.CORBA.NVList _nvl = null;

        if (_opName.equals("TestObjectX_factory"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any id = _obj._orb().create_any();
            org.omg.CORBA.IntHolderHolder id_ = new org.omg.CORBA.IntHolderHolder();
            id.insert_Streamable(id_);
            _nvl.add_value(null, id, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);

            shared.TestObjectXHolder _retHolder = new shared.TestObjectXHolder();
            _retHolder.value = _obj.TestObjectX_factory(id_.value.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("TestObjectA_factory"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any id = _obj._orb().create_any();
            org.omg.CORBA.IntHolderHolder id_ = new org.omg.CORBA.IntHolderHolder();
            id.insert_Streamable(id_);
            _nvl.add_value(null, id, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);

            shared.TestObjectAHolder _retHolder = new shared.TestObjectAHolder();
            _retHolder.value = _obj.TestObjectA_factory(id_.value.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("TestObjectB_factory"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any id = _obj._orb().create_any();
            org.omg.CORBA.IntHolderHolder id_ = new org.omg.CORBA.IntHolderHolder();
            id.insert_Streamable(id_);
            _nvl.add_value(null, id, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);

            shared.TestObjectBHolder _retHolder = new shared.TestObjectBHolder();
            _retHolder.value = _obj.TestObjectB_factory(id_.value.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("TestObjectC_factory"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any id = _obj._orb().create_any();
            org.omg.CORBA.IntHolderHolder id_ = new org.omg.CORBA.IntHolderHolder();
            id.insert_Streamable(id_);
            _nvl.add_value(null, id, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);

            shared.TestObjectCHolder _retHolder = new shared.TestObjectCHolder();
            _retHolder.value = _obj.TestObjectC_factory(id_.value.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("TestObjectD_factory"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any id = _obj._orb().create_any();
            org.omg.CORBA.IntHolderHolder id_ = new org.omg.CORBA.IntHolderHolder();
            id.insert_Streamable(id_);
            _nvl.add_value(null, id, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);

            shared.TestObjectDHolder _retHolder = new shared.TestObjectDHolder();
            _retHolder.value = _obj.TestObjectD_factory(id_.value.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("TestObjectX_nil_factory"))
        {
            _ret = _obj._orb().create_any();
            _req.params(_nvl);

            shared.TestObjectXHolder _retHolder = new shared.TestObjectXHolder();
            _retHolder.value = _obj.TestObjectX_nil_factory();

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("identity"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any x = _obj._orb().create_any();
            org.omg.CORBA.ObjectHolderHolder x_ = new org.omg.CORBA.ObjectHolderHolder();
            x.insert_Streamable(x_);
            _nvl.add_value(null, x, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);

            org.omg.CORBA.ObjectHolderHolder _retHolder = new org.omg.CORBA.ObjectHolderHolder();
            _retHolder.value.value = _obj.identity(x_.value.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("_get_object_attribute"))
        {
            _ret = _obj._orb().create_any();
            _req.params(_nvl);
            org.omg.CORBA.ObjectHolderHolder _retHolder = new org.omg.CORBA.ObjectHolderHolder();
            _retHolder.value.value = _obj.object_attribute();


            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);
            return;
        }
        if (_opName.equals("_set_object_attribute"))
        {
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any value = _obj._orb().create_any();
            org.omg.CORBA.ObjectHolderHolder value_ = new org.omg.CORBA.ObjectHolderHolder();
            value.insert_Streamable(value_);
            _nvl.add_value(null, value, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);
            _obj.object_attribute(value_.value.value);

            return;
        }
        if (_opName.equals("_get_typecode_attribute"))
        {
            _ret = _obj._orb().create_any();
            _req.params(_nvl);
            org.omg.CORBA.TypeCodeHolderHolder _retHolder = new org.omg.CORBA.TypeCodeHolderHolder();
            //--- String _stringRet = _obj.typecode_attribute();

            //--- if ((_stringRet !=null) && (_stringRet.length() > 0))
	    //--- throw new org.omg.CORBA.MARSHAL("String out of bounds.");

            //--- _retHolder.value.value = _stringRet;

            _retHolder.value.value = _obj.typecode_attribute(); // +++

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);
            return;
        }
        if (_opName.equals("_set_typecode_attribute"))
        {
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any value = _obj._orb().create_any();
            org.omg.CORBA.TypeCodeHolderHolder value_ = new org.omg.CORBA.TypeCodeHolderHolder();
            value.insert_Streamable(value_);
            _nvl.add_value(null, value, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);
            _obj.typecode_attribute(value_.value.value);

            return;
        }
        if (_opName.equals("check_object_attribute"))
        {
            _nvl = _obj._orb().create_list(1);
            org.omg.CORBA.Any ior = _obj._orb().create_any();
            org.omg.CORBA.StringHolderHolder ior_ = new org.omg.CORBA.StringHolderHolder();
            ior.insert_Streamable(ior_);
            _nvl.add_value(null, ior, org.omg.CORBA.ARG_IN.value);
            _req.params(_nvl);

            try {
                _obj.check_object_attribute(ior_.value.value);


            } catch (shared.PseudoObjectsTestPackage.failure _ex) {
                shared.PseudoObjectsTestPackage.failureHelper.insert(_ret,_ex);
                _req.except(_ret);
            }
            return;
        }
        if (_opName.equals("check_typecode_attribute"))
        {
            _req.params(_nvl);

            try {
                _obj.check_typecode_attribute();


            } catch (shared.PseudoObjectsTestPackage.failure _ex) {
                shared.PseudoObjectsTestPackage.failureHelper.insert(_ret,_ex);
                _req.except(_ret);
            }
            return;
        }
        if (_opName.equals("object_operation"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(3);
            org.omg.CORBA.Any one = _obj._orb().create_any();
            org.omg.CORBA.ObjectHolderHolder one_ = new org.omg.CORBA.ObjectHolderHolder();
            one.insert_Streamable(one_);
            _nvl.add_value(null, one, org.omg.CORBA.ARG_IN.value);
            org.omg.CORBA.Any two = _obj._orb().create_any();
            org.omg.CORBA.ObjectHolderHolder two_ = new org.omg.CORBA.ObjectHolderHolder();
            two.insert_Streamable(two_);
            _nvl.add_value(null, two, org.omg.CORBA.ARG_INOUT.value);
            org.omg.CORBA.Any three = _obj._orb().create_any();
            org.omg.CORBA.ObjectHolderHolder three_ = new org.omg.CORBA.ObjectHolderHolder();
            three.insert_Streamable(three_);
            _nvl.add_value(null, three, org.omg.CORBA.ARG_OUT.value);
            _req.params(_nvl);

            org.omg.CORBA.ObjectHolderHolder _retHolder = new org.omg.CORBA.ObjectHolderHolder();
            _retHolder.value.value = _obj.object_operation(one_.value.value,two_.value,three_.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        if (_opName.equals("typecode_operation"))
        {
            _ret = _obj._orb().create_any();
            _nvl = _obj._orb().create_list(3);
            org.omg.CORBA.Any one = _obj._orb().create_any();
            org.omg.CORBA.TypeCodeHolderHolder one_ = new org.omg.CORBA.TypeCodeHolderHolder();
            one.insert_Streamable(one_);
            _nvl.add_value(null, one, org.omg.CORBA.ARG_IN.value);
            org.omg.CORBA.Any two = _obj._orb().create_any();
            org.omg.CORBA.TypeCodeHolderHolder two_ = new org.omg.CORBA.TypeCodeHolderHolder();
            two.insert_Streamable(two_);
            _nvl.add_value(null, two, org.omg.CORBA.ARG_INOUT.value);
            org.omg.CORBA.Any three = _obj._orb().create_any();
            org.omg.CORBA.TypeCodeHolderHolder three_ = new org.omg.CORBA.TypeCodeHolderHolder();
            three.insert_Streamable(three_);
            _nvl.add_value(null, three, org.omg.CORBA.ARG_OUT.value);
            _req.params(_nvl);

            org.omg.CORBA.TypeCodeHolderHolder _retHolder = new org.omg.CORBA.TypeCodeHolderHolder();
            _retHolder.value.value = _obj.typecode_operation(one_.value.value,two_.value,three_.value);

            _ret.insert_Streamable(_retHolder);
            _req.result(_ret);

            return;
        }
        else
            throw new org.omg.CORBA.BAD_OPERATION(0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);
    }

    public abstract shared.TestObjectX TestObjectX_factory(int id) ;

    public abstract shared.TestObjectA TestObjectA_factory(int id) ;

    public abstract shared.TestObjectB TestObjectB_factory(int id) ;

    public abstract shared.TestObjectC TestObjectC_factory(int id) ;

    public abstract shared.TestObjectD TestObjectD_factory(int id) ;

    public abstract shared.TestObjectX TestObjectX_nil_factory() ;

    public abstract org.omg.CORBA.Object identity(org.omg.CORBA.Object x) ;

    public abstract org.omg.CORBA.Object object_attribute();

    public abstract void object_attribute(org.omg.CORBA.Object value);

    public abstract org.omg.CORBA.TypeCode typecode_attribute();

    public abstract void typecode_attribute(org.omg.CORBA.TypeCode value);

    public abstract void check_object_attribute(String ior) 
        throws shared.PseudoObjectsTestPackage.failure;

    public abstract void check_typecode_attribute() 
        throws shared.PseudoObjectsTestPackage.failure;

    public abstract org.omg.CORBA.Object object_operation(org.omg.CORBA.Object one,org.omg.CORBA.ObjectHolder two,org.omg.CORBA.ObjectHolder three) ;

    public abstract org.omg.CORBA.TypeCode typecode_operation(org.omg.CORBA.TypeCode one,org.omg.CORBA.TypeCodeHolder two,org.omg.CORBA.TypeCodeHolder three) ;

}